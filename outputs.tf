output "pi-hole-ip" {
  value = "${google_compute_address.static_address.address}"
}
