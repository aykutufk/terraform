# 1. Database için Özel Namespace
resource "kubernetes_namespace" "inosis_db" {
  metadata {
    name = "inosis-db"
  }
}

# 2. MySQL StatefulSet
resource "kubernetes_stateful_set" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.inosis_db.metadata[0].name
  }
  spec {
    service_name = "mysql"
    replicas     = 1
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        # KRİTİK: Podun sadece database_pool node'una gitmesini sağlarız
        node_selector = {
          "cloud.google.com/gke-nodepool" = "inosis-db-pool" 
        }
        toleration {
        operator = "Exists" # Tüm taint'lere (lekelere) eyvallahı var demek
        effect   = "NoSchedule"
        }

        container {
          name  = "mysql"
          image = "mysql:8.0"
          
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "inosis123" # Gerçek projede bunu Secret'tan çekmelisin
          }

          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
        }
      }
    }

    # 10GB Kalıcı Disk (Persistent Disk)
    volume_claim_template {
      metadata {
        name = "mysql-data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard-rwo" # Google'ın standart kalıcı diski
        resources {
          requests = {
            storage = "10Gi"
          }
        }
      }
    }
  }
}

# 3. Veritabanına Erişim İçin Servis
resource "kubernetes_service" "mysql_service" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.inosis_db.metadata[0].name
  }
  spec {
    selector = {
      app = "mysql"
    }
    port {
      port = 3306
    }
    cluster_ip = "None" # Headless servis
  }
}