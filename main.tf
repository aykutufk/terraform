terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }
  backend "gcs" {
    bucket  = "inosis-vault-backups-project-0497ef4c-ab4c-42b5-96c" # GCP'de önceden oluşturulmuş bir bucket adı
    prefix  = "terraform/state"
  }
}
provider "google" {
  project = "project-0497ef4c-ab4c-42b5-96c"
  region  = "us-central1"
  zone    = "us-central1-a"
}
data "google_client_config" "default" {}

data "google_container_cluster" "inosis_cluster" {
  name     = "inosis-gke-cluster"
  location = "us-central1-a" # Senin cluster'ın lokasyonu neyse o kalsın
}
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.inosis_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.inosis_cluster.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.inosis_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.inosis_cluster.master_auth[0].cluster_ca_certificate
    )
  }
}