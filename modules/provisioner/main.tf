resource "null_resource" "backup_wireguard_configs" {
  triggers = {
    instance_ip = var.instance_ip
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      $ErrorActionPreference = "SilentlyContinue"
      New-Item -ItemType Directory -Force -Path "${path.module}/wg_backup" | Out-Null
      $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
      
      ssh -i ${var.privatekeypath} -o StrictHostKeyChecking=no -o UserKnownHostsFile=$null ${var.user}@${var.instance_ip} "sudo cat /home/${var.user}/.amnezia-wg-easy/wg0.conf" | Out-File -FilePath "${path.module}/wg_backup/wg0.conf.backup.$timestamp" -Encoding utf8 -NoNewline 2>$null
      ssh -i ${var.privatekeypath} -o StrictHostKeyChecking=no -o UserKnownHostsFile=$null ${var.user}@${var.instance_ip} "sudo cat /home/${var.user}/.amnezia-wg-easy/wg0.json" | Out-File -FilePath "${path.module}/wg_backup/wg0.json.backup.$timestamp" -Encoding utf8 -NoNewline 2>$null
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "install_docker" {
  depends_on = [null_resource.backup_wireguard_configs]

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/startup.sh"
    destination = "/tmp/startup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/startup.sh",
      "bash /tmp/startup.sh '${var.user}'"
    ]
  }
}

resource "null_resource" "clone_repository" {
  depends_on = [null_resource.install_docker]

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "remote-exec" {
    inline = [
      "if [ -d /tmp/amnezia-wg-easy ]; then rm -rf /tmp/amnezia-wg-easy; fi",
      "git clone https://github.com/w0rng/amnezia-wg-easy /tmp/amnezia-wg-easy"
    ]
  }
}

resource "null_resource" "build_amnezia_image" {
  depends_on = [null_resource.clone_repository]

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/amnezia-wg-easy",
      "docker build -t amnezia-wg-easy ."
    ]
  }
}

data "local_file" "wg0_conf" {
  count    = var.enable_wg_configs ? 1 : 0
  filename = "${path.module}/wg_backup/wg0.conf"
}

data "local_file" "wg0_json" {
  count    = var.enable_wg_configs ? 1 : 0
  filename = "${path.module}/wg_backup/wg0.json"
}

resource "null_resource" "copy_wireguard_configs" {
  count = var.enable_wg_configs ? 1 : 0

  connection {
    agent       = false
    timeout     = "500s"
    host        = var.instance_ip
    user        = var.user
    private_key = file(var.privatekeypath)
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${data.local_file.wg0_conf[0].content}' | sudo tee /home/${var.user}/.amnezia-wg-easy/wg0.conf > /dev/null",
      "echo '${data.local_file.wg0_json[0].content}' | sudo tee /home/${var.user}/.amnezia-wg-easy/wg0.json > /dev/null",
      "sudo chown root:root /home/${var.user}/.amnezia-wg-easy/wg0.conf",
      "sudo chown root:root /home/${var.user}/.amnezia-wg-easy/wg0.json"
    ]
  }
}

resource "null_resource" "run_amnezia_docker_container" {
  depends_on = [null_resource.build_amnezia_image]

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/amnezia-wg-easy.sh"
    destination = "/home/${var.user}/amnezia-wg-easy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.user}/amnezia-wg-easy.sh",
      "bash /home/${var.user}/amnezia-wg-easy.sh ${var.wg_host} '${var.wg_password}'"
    ]
  }
}

resource "null_resource" "setup_cron_restart" {
  depends_on = [null_resource.run_amnezia_docker_container]

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/setup-cron-restart.sh"
    destination = "/home/${var.user}/setup-cron-restart.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.user}/setup-cron-restart.sh",
      "bash /home/${var.user}/setup-cron-restart.sh '${var.cron_restart_schedule}'"
    ]
  }
}