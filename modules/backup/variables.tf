variable "instance_id" {
  type        = string
  description = "ID of the compute instance"
}

variable "instance_ip" {
  type        = string
  description = "Public IP address of the compute instance"
}

variable "user" {
  type        = string
  description = "SSH username for VM instance access"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key file (id_rsa)"
}

variable "backup_path" {
  type        = string
  description = "Path to backup directory"
  default     = "./modules/backup/wg_backup"
}

