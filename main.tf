provider "google" {
  project     = var.project
  region      = var.region
  credentials = var.gcp_credentials_json
}

module "instance" {
  source        = "./modules/instance"
  project       = var.project
  region        = var.region
  user          = var.user
  publickeypath = var.publickeypath
  email         = var.email
  instance_name = var.instance_name
  boot_image    = var.boot_image
  machine_type  = var.machine_type
  zone_suffix   = var.zone_suffix
}

# IMPORTANT: If instance needs to be recreated, run backup first:
# terraform apply -target="module.backup"
# This ensures backup runs BEFORE instance destruction
module "backup" {
  source        = "./modules/backup"
  instance_id   = module.instance.vpn_instance.id
  instance_ip   = module.instance.instance_ip
  user          = var.user
  privatekeypath = var.privatekeypath
}

module "provisioner" {
  depends_on            = [module.instance.vpn_instance, module.backup]
  source                = "./modules/provisioner"
  instance_ip           = module.instance.instance_ip
  user                  = var.user
  privatekeypath        = var.privatekeypath
  wg_host               = var.wg_host
  wg_password           = var.wg_password
  cron_restart_schedule = var.cron_restart_schedule
  enable_wg_configs     = var.enable_wg_configs
}
