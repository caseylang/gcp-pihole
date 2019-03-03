provider "google" {
  project = "${var.gcp_project}"
  region = "us-central1"
  zone = "us-central1-a"
}

resource "google_compute_network" "dns_network" {
  name = "dns-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "main" {
  name = "main"
  network = "${google_compute_network.dns_network.name}"
  ip_cidr_range = "192.168.10.0/24"
}

resource "google_compute_firewall" "allow_internal" {
  name = "allow-internal"
  network = "${google_compute_network.dns_network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["${google_compute_subnetwork.main.ip_cidr_range}"]
}

resource "google_compute_firewall" "allow_dns" {
  name = "allow-dns"
  network = "${google_compute_network.dns_network.name}"

  allow {
    protocol = "tcp"
    ports = ["53"]
  }

  allow {
    protocol = "udp"
    ports = ["53"]
  }

  target_tags = ["pi-hole"]
  source_ranges = ["${var.local_ip}"]
}

resource "google_compute_firewall" "allow_ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.dns_network.name}"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  target_tags = ["pi-hole"]
  source_ranges = ["${var.local_ip}"]
}

resource "google_compute_firewall" "allow_http" {
  name = "allow-http"
  network = "${google_compute_network.dns_network.name}"

  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }

  allow {
    protocol = "udp"
    ports = ["80", "443"]
  }

  target_tags = ["pi-hole"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "static_address" {
  name = "pi-hole-address"
}

data "google_compute_image" "debian_image" {
  family = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance" "pi_hole" {
  name = "pi-hole"
  machine_type = "f1-micro"

  tags = ["pi-hole"]

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.debian_image.self_link}"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.main.name}"

    access_config {
      nat_ip = "${google_compute_address.static_address.address}"
    }
  }
}
