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

module "provisioner" {
  depends_on            = [module.instance.vpn_instance]
  source                = "./modules/provisioner"
  instance_ip           = module.instance.instance_ip
  user                  = var.user
  privatekeypath        = var.privatekeypath
  wg_host               = var.wg_host
  wg_password           = var.wg_password
  cron_restart_schedule = var.cron_restart_schedule
}
