variable "user" {
  type        = string
  description = "SSH username for VM instance access"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key file (id_rsa)"
}

variable "instance_ip" {
  type        = string
  description = "Public IP address of the compute instance"
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

variable "enable_wg_configs" {
  type        = bool
  description = "Enable WireGuard configuration files backup/restore"
  default     = false
}

variable "cron_restart_schedule" {
  type        = string
  description = "Cron schedule for container restart (default: daily at 3 AM)"
  default     = "0 3 * * *"
}
