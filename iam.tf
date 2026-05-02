# Vault'un GCS bucket'ına yazabilmesi için gereken IAM izni
resource "google_storage_bucket_iam_member" "vault_backup_storage_admin" {
  bucket = google_storage_bucket.vault_backup_bucket.name
  role   = "roles/storage.objectAdmin"
  
  # Buradaki 'member' kısmı, Vault'un GCP tarafındaki kimliği olmalı
  # Eğer Workload Identity kullanıyorsan, bu genellikle GCP SA'dır.
  member = "serviceAccount:vault-terraform-admin@project-0497ef4c-ab4c-42b5-96c.iam.gserviceaccount.com"
}