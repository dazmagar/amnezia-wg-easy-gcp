output "backup_resource_id" {
  description = "ID of the backup resource"
  value       = null_resource.backup_wireguard_configs.id
}

