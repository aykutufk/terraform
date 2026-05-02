resource "google_compute_instance" "monitoring_vm" {
  name         = "inosis-monitoring"
  machine_type = "e2-medium" # 2 vCPU, 4GB RAM
  zone         = "us-central1-a"
  depends_on   = [google_project_service.api]
  
  # Güvenlik duvarının bu makineyi tanıması için bir etiket veriyoruz
  tags         = ["monitoring-hub"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.inosis_vpc.id
    subnetwork = google_compute_subnetwork.inosis_subnet.id
    access_config {
      # Dışarıdan Grafana'ya erişebilmen için statik olmayan bir IP atar
    }
  }

  # MAKİNE AÇILDIĞINDA OTOMATİK ÇALIŞACAK KODLAR (DOCKER & İZLEME ARAÇLARI)
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # 1. Docker Kurulumu
    apt-get update
    apt-get install -y docker.io docker-compose

    # 2. Araçları ayağa kaldırmak için docker-compose dosyası oluştur
    mkdir -p /opt/monitoring
    cd /opt/monitoring

    cat << 'COMPOSE' > docker-compose.yml
    version: '3'
    services:
      prometheus:
        image: prom/prometheus:latest
        ports:
          - "9090:9090"
        command:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--web.enable-remote-write-receiver' # ÇOK ÖNEMLİ: GKE'den gelecek verileri kabul etmesi için
      loki:
        image: grafana/loki:latest
        ports:
          - "3100:3100"
      grafana:
        image: grafana/grafana:latest
        ports:
          - "3000:3000"
        environment:
          - GF_SECURITY_ADMIN_PASSWORD=inosis123
    COMPOSE

    # 3. Konteynerleri başlat
    docker-compose up -d
  EOF
}

# GÜVENLİK DUVARI: Grafana, Prometheus ve Loki portlarını açıyoruz
resource "google_compute_firewall" "monitoring_fw" {
  name    = "allow-monitoring-ports"
  network = google_compute_network.inosis_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3000", "3100", "9090"]
  }

  # Şimdilik her yerden erişime açıyoruz (Test ortamı)
  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["monitoring-hub"]
}