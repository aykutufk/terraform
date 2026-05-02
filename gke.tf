resource "google_container_cluster" "inosis_cluster" {
  name     = "inosis-gke-cluster"
  location = "us-central1-a"
  deletion_protection = false
  workload_identity_config {
    workload_pool = "project-0497ef4c-ab4c-42b5-96c.svc.id.goog"
  }
  
  # Default node pool'u hemen siliyoruz, kendimiz özel pool kuracağız
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.inosis_vpc.id
  subnetwork               = google_compute_subnetwork.inosis_subnet.id
  private_cluster_config {
    enable_private_nodes    = true        # İşte bu "true", o External IP'leri silecek olan sihirli değneke
    enable_private_endpoint = false       # kubectl komutların çalışmaya devam etsin diye bunu false bırakıyoruz
    master_ipv4_cidr_block  = "172.16.0.0/28" # Senin 10.0.0.0 ağınla çakışmayan, Master tüneli için özel alan
  }
}

resource "google_container_node_pool" "app_pool" {
  name       = "inosis-app-pool-v2"
  location   = "us-central1-a"
  cluster    = google_container_cluster.inosis_cluster.name
  node_count = 2 # Bu senin node01 makinen

  node_config {
    machine_type = "e2-standard-2"
    preemptible  = true
    disk_size_gb = 30
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
      workload_metadata_config {
      mode = "GKE_METADATA"
    }
    labels = {
      layer = "application"
    }
  }
}

resource "google_container_node_pool" "db_pool" {
  name       = "inosis-db-pool"
  location   = "us-central1-a"
  cluster    = google_container_cluster.inosis_cluster.name
  node_count = 1 # Bu da senin node02 makinen

  node_config {
    machine_type = "e2-standard-2"
    preemptible  = true
    disk_size_gb = 30
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      layer = "database"
    }

    # Sadece bu pool'daki makineye taint veriyoruz
    taint {
      key    = "database"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }
}