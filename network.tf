# VPC Oluşturma
resource "google_compute_network" "inosis_vpc" {
  name                    = "inosis-vpc"
  auto_create_subnetworks = false
}

# Subnet (Yereldeki ağının karşılığı)
resource "google_compute_subnetwork" "inosis_subnet" {
  name          = "inosis-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.inosis_vpc.id
  private_ip_google_access = true
  

   secondary_ip_range {
    range_name    = "gke-pods-range"
    ip_cidr_range = "10.48.0.0/14"
  }

  # Servisler için ikincil IP aralığı
  secondary_ip_range {
    range_name    = "gke-services-range"
    ip_cidr_range = "10.52.0.0/20"
  }
  lifecycle {
    ignore_changes = [ secondary_ip_range
  ]
  }
 
}

# Cloud NAT (Gateway01 yerine geçecek olan servis)
resource "google_compute_router" "router" {
  name    = "inosis-router"
  network = google_compute_network.inosis_vpc.id
  region  = "us-central1"
}

resource "google_compute_router_nat" "nat" {
  name                               = "inosis-nat"
  router                             = google_compute_router.router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}