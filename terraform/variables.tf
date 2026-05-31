variable "yc_token" {
  description = "Yandex Cloud IAM token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "db_name" {
  description = "Redmine PostgreSQL database name"
  type        = string
  default     = "redmine"
}

variable "db_user" {
  description = "Redmine PostgreSQL user"
  type        = string
  default     = "redmine"
}

variable "db_password" {
  description = "Redmine PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the deployed application"
  type        = string
  default     = "edavholod.ru"
}

variable "dns_zone_id" {
  description = "Existing Yandex Cloud DNS zone ID"
  type        = string
}

variable "certificate_id" {
  description = "Existing Yandex Certificate Manager certificate ID"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog application key"
  type        = string
  sensitive   = true
}
