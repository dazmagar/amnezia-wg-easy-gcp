# Amnezia WG Easy - Terraform Deployment for GCP

Terraform module for deploying Amnezia WG Easy VPN server on Google Cloud Platform.

## Links

- **Amnezia VPN**: https://amnezia.org/en
- **Amnezia WG Easy**: https://github.com/w0rng/amnezia-wg-easy

## Features

- Automated deployment of WireGuard VPN server using Amnezia WG Easy
- Automatic Docker installation and container management
- Automatic backup of WireGuard configurations (organized by year)
- Automatic cron job setup for container restart
- Node.js 22 LTS compatibility fixes for upstream repository
- Cross-platform backup scripts (Linux/macOS/Windows)

## Prerequisites

- Terraform >= 1.0
- GCP service account with Compute Engine permissions
- SSH key pair for instance access
- Bcrypt hashed password for WireGuard admin panel

## Quick Start

1. Copy example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Deploy infrastructure:
   ```bash
   terraform apply
   ```

## Configuration

See `terraform.tfvars.example` for all available options.

### Important Variables

- `gcp_credentials_json` - Path to GCP service account JSON file
- `project` - GCP project ID
- `wg_host` - WireGuard host IP or FQDN
- `wg_password` - Bcrypt hashed password for admin panel
- `enable_wg_configs` - Enable config backup/restore (default: false)
- `cron_restart_schedule` - Cron schedule for container restart (default: "0 3 * * *")

## Backup Structure

Backup files are organized by year:
```
modules/backup/wg_backup/
  ├── wg0.conf              # Latest version (for restore)
  ├── wg0.json             # Latest version (for restore)
  └── 2025/                 # Year directory
      ├── wg0.conf.backup.20251116_164040
      └── wg0.json.backup.20251116_164040
```

Backups are automatically created on each `terraform apply`.

## Important Notes

### Before Instance Recreation

If you need to recreate the instance, run backup first:
```bash
terraform apply -target="module.backup"
```

This ensures backup runs BEFORE instance destruction.

### Updating Components

In case of WG updates or component changes:
```bash
terraform apply -replace="module.provisioner.null_resource.install_docker"
terraform apply -replace="module.provisioner.null_resource.clone_repository"
terraform apply -replace="module.provisioner.null_resource.build_amnezia_image"
terraform apply -replace="module.provisioner.null_resource.copy_wireguard_configs"  # requires enable_wg_configs = true
terraform apply -replace="module.provisioner.null_resource.run_amnezia_docker_container"
terraform apply -replace="module.provisioner.null_resource.setup_cron_restart"
```

## Technical Details

### Node.js Compatibility

The module automatically fixes Node.js version compatibility issues in the upstream repository:
- Updates base Docker image from Node.js 18/20 to Node.js 22 LTS
- Skips incompatible npm@latest installation if needed

### Docker Commands

All Docker commands use `sudo` to handle permission issues, as the user may not be in the docker group in the current SSH session.

### Cron Job

Cron job is automatically configured to restart the container on schedule (default: daily at 3 AM). To verify:
```bash
ssh user@instance_ip
crontab -l
```

## Troubleshooting

### Check Container Status
```bash
ssh user@instance_ip
sudo docker ps -a --filter "name=amnezia-wg-easy"
```

### View Container Logs
```bash
ssh user@instance_ip
sudo docker logs amnezia-wg-easy
```

### Check Build Logs
```bash
ssh user@instance_ip
cat /tmp/docker-build.log
```

### Verify Cron Job
```bash
ssh user@instance_ip
crontab -l
```
