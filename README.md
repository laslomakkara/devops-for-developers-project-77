### Hexlet tests and linter status:
[![Actions Status](https://github.com/laslomakkara/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/laslomakkara/devops-for-developers-project-77/actions)

# DevOps for Developers Project 77

Infrastructure as Code project for deploying Redmine to Yandex Cloud.

The project creates cloud infrastructure with Terraform, deploys the application with Ansible, connects a domain with HTTPS, and configures monitoring with Datadog.

## Application

The deployed application is **Redmine**, a web-based project management system.

Redmine runs in Docker containers on two virtual machines and uses Yandex Managed PostgreSQL as a database.

## Deployment note

The infrastructure was successfully created, the Redmine application was deployed and verified, and monitoring was configured.

After verification, the infrastructure was destroyed to avoid unnecessary cloud costs.

Because of this, the application URL may not be available permanently:

```bash
https://edavholod.ru
```

## Infrastructure

Terraform creates the following infrastructure:

- VPC network and subnet
- Security groups
- 2 virtual machines used as Redmine web servers
- Yandex Managed PostgreSQL database
- Application Load Balancer
- HTTPS listener with Yandex Certificate Manager certificate
- DNS A-record for the application domain
- Datadog monitor for Redmine HTTP availability

The infrastructure is created in one availability zone:

```bash
ru-central1-a
```

## Domain

The project uses an existing domain:

```bash
edavholod.ru
```

The domain is delegated to Yandex Cloud DNS. Terraform manages the DNS A-record and points it to the external IP address of the Application Load Balancer.

The application is available over HTTPS using an existing certificate from Yandex Certificate Manager.

## Monitoring

Monitoring is configured with Datadog.

Terraform creates a Datadog monitor:

```bash
Project 77 Redmine HTTP check
```

Ansible installs the Datadog Agent on both virtual machines and configures an HTTP check for the Redmine application.

External availability monitoring is configured separately using an uptime monitoring service for:

```bash
https://edavholod.ru
```

## Secrets

Secret values are stored in an encrypted Ansible Vault file:

```bash
ansible/vault.yml
```

The Vault file contains sensitive values such as:

```yaml
yc_token: "..."
yc_cloud_id: "..."
yc_folder_id: "..."
db_password: "..."
dns_zone_id: "..."
certificate_id: "..."
dd_api_key: "..."
dd_app_key: "..."
```

Local Terraform variable files are not committed to the repository.

## Terraform backend

Terraform state is stored remotely in Yandex Object Storage using the S3-compatible backend.

The backend configuration is stored in:

```bash
terraform/backend.tf
```

Sensitive backend values are passed from a local file:

```bash
terraform/backend.hcl
```

This file is not committed to the repository.

Example backend initialization:

```bash
terraform -chdir=terraform init -backend-config=backend.hcl -reconfigure
```

## Makefile commands

### Terraform

Initialize Terraform with remote backend:

```bash
make init
```

Initialize Terraform without remote backend for local validation:

```bash
make init-local
```

Format Terraform files:

```bash
make fmt
```

Validate Terraform configuration:

```bash
make validate
```

Show Terraform plan:

```bash
make plan
```

Create cloud infrastructure:

```bash
make apply
```

Show Terraform outputs:

```bash
make output
```

Destroy cloud infrastructure:

```bash
make destroy
```

### Ansible

Install required Ansible roles and collections:

```bash
make install-ansible
```

Generate Ansible inventory from Terraform outputs:

```bash
make inventory
```

Deploy Redmine and Datadog Agent:

```bash
make deploy
```

Run only preparation tasks:

```bash
make deploy-prepare
```

Deploy only the Redmine container:

```bash
make deploy-app
```

Deploy only Datadog monitoring configuration:

```bash
make deploy-monitoring
```

## Deployment process

### 1. Initialize Terraform backend

```bash
terraform -chdir=terraform init -backend-config=backend.hcl -reconfigure
```

### 2. Validate Terraform

```bash
make fmt
make validate
```

### 3. Review Terraform plan

```bash
make plan
```

### 4. Create infrastructure

```bash
make apply
```

### 5. Generate Ansible inventory

```bash
make inventory
```

### 6. Install Ansible dependencies

```bash
make install-ansible
```

### 7. Deploy application

```bash
make deploy
```

### 8. Open application

```bash
https://edavholod.ru
```

## Cleanup

Destroy the infrastructure after testing:

```bash
make destroy
```