resource "null_resource" "install_docker" {
  triggers = {
    instance_ip = var.instance_ip
    user        = var.user
  }

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
      # Check if Docker is already installed and running
      "if sudo docker --version &> /dev/null && sudo systemctl is-active --quiet docker; then",
      "  echo 'Docker is already installed and running: $(sudo docker --version)'",
      "else",
      "  # If not installed, run installation script",
      "  chmod +x /tmp/startup.sh",
      "  bash /tmp/startup.sh '${var.user}'",
      "  # Verify Docker installation (use sudo since usermod requires new session to take effect)",
      "  if ! sudo docker --version &> /dev/null; then",
      "    if [ ! -f /usr/bin/docker ]; then",
      "      echo 'Error: Docker installation failed'",
      "      exit 1",
      "    fi",
      "  fi",
      "  echo 'Docker installed successfully'",
      "fi"
    ]
  }
}

resource "null_resource" "clone_repository" {
  depends_on = [null_resource.install_docker]

  triggers = {
    instance_ip = var.instance_ip
    user        = var.user
  }

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

  triggers = {
    instance_ip = var.instance_ip
    user        = var.user
    repository  = null_resource.clone_repository.id
  }

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
      "# Fix Node.js version compatibility issue in Dockerfile",
      "# Option 1: Update base image to Node.js 22 LTS if FROM node:18 or node:20 is used",
      "if grep -q 'FROM node:18' Dockerfile || grep -q 'FROM node:20' Dockerfile; then",
      "  if ! grep -q 'FROM node:22' Dockerfile; then",
      "    echo 'Fixing Dockerfile: updating Node.js base image to 22 LTS'",
      "    sed -i 's/FROM node:18/FROM node:22/' Dockerfile",
      "    sed -i 's/FROM node:20/FROM node:22/' Dockerfile",
      "  fi",
      "fi",
      "# Option 2: If base image update doesn't work, skip npm@latest install",
      "if grep -q 'npm install -g npm@latest' Dockerfile && ! grep -q '# RUN npm install -g npm@latest' Dockerfile; then",
      "  echo 'Fixing Dockerfile: skipping npm@latest install to avoid Node.js version conflict'",
      "  sed -i 's/RUN npm install -g npm@latest/# RUN npm install -g npm@latest  # Skipped: incompatible with Node.js v18/' Dockerfile",
      "fi",
      "# Remove existing image if it exists to force rebuild",
      "if sudo docker images -q amnezia-wg-easy | grep -q .; then",
      "  echo 'Removing existing Docker image to force rebuild...'",
      "  sudo docker rmi amnezia-wg-easy || true",
      "fi",
      "echo 'Building Docker image amnezia-wg-easy...'",
      "if ! sudo docker build -t amnezia-wg-easy .; then",
      "  echo 'ERROR: Docker build failed'",
      "  exit 1",
      "fi",
      "if ! sudo docker images -q amnezia-wg-easy | grep -q .; then",
      "  echo 'ERROR: Docker image verification failed - image does not exist after build'",
      "  exit 1",
      "fi",
      "echo 'Docker image built successfully'"
    ]
  }
}

data "local_file" "wg0_conf" {
  count    = var.enable_wg_configs ? 1 : 0
  filename = "${path.root}/modules/backup/wg_backup/wg0.conf"
}

data "local_file" "wg0_json" {
  count    = var.enable_wg_configs ? 1 : 0
  filename = "${path.root}/modules/backup/wg_backup/wg0.json"
}

resource "null_resource" "copy_wireguard_configs" {
  count = var.enable_wg_configs ? 1 : 0

  depends_on = [null_resource.build_amnezia_image]

  connection {
    agent       = false
    timeout     = "500s"
    host        = var.instance_ip
    user        = var.user
    private_key = file(var.privatekeypath)
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.user}/.amnezia-wg-easy",
      "echo '${data.local_file.wg0_conf[0].content}' | sudo tee /home/${var.user}/.amnezia-wg-easy/wg0.conf > /dev/null",
      "echo '${data.local_file.wg0_json[0].content}' | sudo tee /home/${var.user}/.amnezia-wg-easy/wg0.json > /dev/null",
      "sudo chown root:root /home/${var.user}/.amnezia-wg-easy/wg0.conf",
      "sudo chown root:root /home/${var.user}/.amnezia-wg-easy/wg0.json"
    ]
  }
}

resource "null_resource" "run_amnezia_docker_container" {
  depends_on = [null_resource.build_amnezia_image, null_resource.copy_wireguard_configs]

  triggers = {
    instance_ip  = var.instance_ip
    user         = var.user
    wg_host      = var.wg_host
    image_built  = null_resource.build_amnezia_image.id
  }

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
  depends_on = [null_resource.install_docker, null_resource.run_amnezia_docker_container]

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