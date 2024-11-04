output "vpn_instance" {
  value = google_compute_instance.vpn_instance
}

output "instance_ip" {
  value = google_compute_instance.vpn_instance.network_interface[0].access_config[0].nat_ip
}
