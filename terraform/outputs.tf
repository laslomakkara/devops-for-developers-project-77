output "application_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}

output "load_balancer_ip" {
  description = "External IP address of the HTTPS load balancer"
  value       = yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "web_server_public_ips" {
  description = "Public IP addresses of Redmine web servers"
  value       = yandex_compute_instance.web[*].network_interface[0].nat_ip_address
}

output "web_server_private_ips" {
  description = "Private IP addresses of Redmine web servers"
  value       = yandex_compute_instance.web[*].network_interface[0].ip_address
}

output "postgres_host" {
  description = "PostgreSQL host used by Redmine"
  value       = yandex_mdb_postgresql_cluster.redmine.host[0].fqdn
}
