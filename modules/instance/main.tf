resource "google_compute_firewall" "default" {
  name    = "vpn-server-firewall"
  network = "default"
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["22", "51821"]
  }

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpn-server"]
}

resource "google_compute_address" "static" {
  name       = "vpn-static-ip"
  project    = var.project
  region     = var.region
  depends_on = [google_compute_firewall.default]
}

resource "google_compute_instance" "vpn_instance" {
  name         = "vpn-instance"
  machine_type = "e2-micro"
  project      = var.project
  zone         = "${var.region}-b"
  tags         = ["vpn-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20221014"
      size  = "10"
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata = {
    ssh-keys = "${var.user}:${file(var.publickeypath)}"
  }

  depends_on = [google_compute_firewall.default]

  service_account {
    email  = var.email
    scopes = ["compute-ro"]
  }

}
