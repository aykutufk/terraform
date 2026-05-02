locals {
  project_id = "project-0497ef4c-ab4c-42b5-96c"
  region     = "us-central1"
  zone       = "us-central1-a"
  apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}