

resource "google_compute_firewall" "allow_k8s_traffic" {
  name    = "allow-k8s-traffic"
  network = google_compute_network.inosis_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3000", "3100"] # App, Grafana, Loki portları
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "allow-ssh-iap"
  network = google_compute_network.inosis_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Sadece Google'ın IAP IP aralığından gelen isteklere izin ver
  source_ranges = ["35.235.240.0/20"]
}