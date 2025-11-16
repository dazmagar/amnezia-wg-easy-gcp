# IMPORTANT: If instance needs to be recreated, run backup first:
# terraform apply -target="module.backup"
# This ensures backup runs BEFORE instance destruction
resource "null_resource" "backup_wireguard_configs" {
  triggers = {
    instance_id = var.instance_id
    instance_ip = var.instance_ip
    timestamp   = timestamp()
  }

  # Cross-platform: Try shell script first (works on Linux, macOS, Git Bash on Windows)
  # PowerShell script will be used as fallback on Windows if shell fails
  provisioner "local-exec" {
    command     = "${path.module}/backup.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
    on_failure = continue
  }

  # Windows PowerShell fallback (only runs if shell script failed or not available)
  provisioner "local-exec" {
    command     = "${path.module}/backup.ps1"
    interpreter = ["PowerShell", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
    on_failure = continue
  }
}

