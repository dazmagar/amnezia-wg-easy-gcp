variable "gcp_credentials_json" {
  type        = string
  description = "Path to GCP service account credentials JSON file"
}

variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for resources deployment"
}

variable "user" {
  type        = string
  description = "SSH username for VM instance access"
}

variable "publickeypath" {
  type        = string
  description = "Path to public SSH key file (id_rsa.pub)"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key file (id_rsa)"
}

variable "email" {
  type        = string
  description = "GCP service account email address"
}

variable "wg_host" {
  type        = string
  description = "WireGuard host IP address or FQDN"
}

variable "wg_password" {
  type        = string
  description = "WireGuard admin password (bcrypt hashed)"
  sensitive   = true
}

variable "instance_name" {
  type        = string
  description = "Name of the compute instance"
  default     = "vpn-server"
}

variable "boot_image" {
  type        = string
  description = "Boot image family for the instance"
  default     = "ubuntu-2404-lts-amd64"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the compute instance"
  default     = "e2-micro"
}

variable "zone_suffix" {
  type        = string
  description = "Zone suffix (a, b, c, etc.)"
  default     = "b"
}

variable "cron_restart_schedule" {
  type        = string
  description = "Cron schedule for container restart (default: daily at 3 AM)"
  default     = "0 3 * * *"
}