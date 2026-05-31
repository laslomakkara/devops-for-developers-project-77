data "yandex_compute_image" "ubuntu" {
  family    = "ubuntu-2204-lts"
  folder_id = "standard-images"
}

resource "yandex_vpc_network" "main" {
  name = "project-77-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "project-77-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "alb" {
  name       = "project-77-alb-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "Allow HTTPS from internet"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow HTTP to web servers"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web" {
  name       = "project-77-web-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    description       = "Allow HTTP from load balancer"
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb.id
  }

  ingress {
    description    = "Allow SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow all outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "postgres" {
  name       = "project-77-postgres-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    description       = "Allow PostgreSQL from web servers"
    protocol          = "TCP"
    port              = 6432
    security_group_id = yandex_vpc_security_group.web.id
  }

  ingress {
    description       = "Allow PostgreSQL direct from web servers"
    protocol          = "TCP"
    port              = 5432
    security_group_id = yandex_vpc_security_group.web.id
  }

  egress {
    description    = "Allow all outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_mdb_postgresql_cluster" "redmine" {
  name        = "project-77-postgres"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.main.id

  config {
    version = 15

    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.main.id
  }

  security_group_ids = [yandex_vpc_security_group.postgres.id]
}

resource "yandex_mdb_postgresql_user" "redmine" {
  cluster_id = yandex_mdb_postgresql_cluster.redmine.id
  name       = var.db_user
  password   = var.db_password
}

resource "yandex_mdb_postgresql_database" "redmine" {
  cluster_id = yandex_mdb_postgresql_cluster.redmine.id
  name       = var.db_name
  owner      = yandex_mdb_postgresql_user.redmine.name
}

resource "yandex_compute_instance" "web" {
  count = 2

  name        = "project-77-redmine-${count.index + 1}"
  platform_id = "standard-v1"
  zone        = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  depends_on = [
    yandex_mdb_postgresql_database.redmine
  ]
}

resource "yandex_alb_target_group" "web" {
  name = "project-77-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.web

    content {
      subnet_id  = yandex_vpc_subnet.main.id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "web" {
  name = "project-77-backend-group"

  http_backend {
    name             = "redmine-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout  = "5s"
      interval = "10s"

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web" {
  name = "project-77-router"
}

resource "yandex_alb_virtual_host" "web" {
  name           = "project-77-virtual-host"
  http_router_id = yandex_alb_http_router.web.id

  route {
    name = "project-77-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  name       = "project-77-alb"
  network_id = yandex_vpc_network.main.id

  allocation_policy {
    location {
      zone_id   = var.yc_zone
      subnet_id = yandex_vpc_subnet.main.id
    }
  }

  listener {
    name = "https-listener"

    endpoint {
      address {
        external_ipv4_address {}
      }

      ports = [443]
    }

    tls {
      default_handler {
        certificate_ids = [var.certificate_id]

        http_handler {
          http_router_id = yandex_alb_http_router.web.id
        }
      }
    }
  }

  security_group_ids = [yandex_vpc_security_group.alb.id]
}

resource "yandex_dns_recordset" "app" {
  zone_id = var.dns_zone_id
  name    = "${var.domain_name}."
  type    = "A"
  ttl     = 300

  data = [
    yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
  ]
}
