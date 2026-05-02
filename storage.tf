resource "google_storage_bucket" "vault_backup_bucket" {
  name          = "inosis-vault-backups-project-0497ef4c-ab4c-42b5-96c"
  location      = "us-central1"
  force_destroy = true

  uniform_bucket_level_access = true  # 👈 EKLE

  versioning {
    enabled = true
  }
}