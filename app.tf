# 1. Sabit Dış IP
resource "google_compute_global_address" "nginx_static_ip" {
  name = "inosis-nginx-static-ip"
}

# 2. Uygulama Namespace'i
resource "kubernetes_namespace_v1" "inosis_app" {
  metadata {
    name = "inosis-app"
  }
}

# YENİ: inosis-app namespace'i için Service Account
resource "kubernetes_service_account_v1" "app_vault_sa" {
  metadata {
    name      = "vault-sa"
    namespace = kubernetes_namespace_v1.inosis_app.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "nginx_app" {
  depends_on = [kubernetes_service_account_v1.app_vault_sa]

  metadata {
    name      = "inosis-nginx-app"
    namespace = kubernetes_namespace_v1.inosis_app.metadata[0].name
    labels = {
      app = "nginx"
    }
    # NOT: Annotations buradan KALDARILDI!
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
        # DOĞRU YER BURASI: Pod şablonunun metadata'sı
        annotations = {
          "vault.hashicorp.com/agent-inject"                   = "true"
          "vault.hashicorp.com/role"                           = "inosis-read-role"
          "vault.hashicorp.com/agent-inject-secret-db-creds"   = "inosis/db-config"
          "vault.hashicorp.com/agent-inject-template-db-creds" = <<EOT
            {{- with secret "inosis/db-config" -}}
            export DB_USER="{{ .Data.data.username }}"
            export DB_PASS="{{ .Data.data.password }}"
            export DB_HOST="mysql.inosis-db.svc.cluster.local"
            {{- end -}}
          EOT
        }
      }
      spec {
        service_account_name = "vault-sa"
        
        node_selector = {
          "cloud.google.com/gke-nodepool" = "inosis-app-pool-v2"
        }
      affinity {
        pod_anti_affinity {
          required_during_scheduling_ignored_during_execution {
            label_selector {
              match_expressions {
                key      = "app"
                operator = "In"
                values   = ["nginx"]
              }
            }
            topology_key = "kubernetes.io/hostname"
          }
        }
      }
      
        
        container {
          name  = "nginx-container"
          image = "nginx:latest"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# 4. Service
resource "kubernetes_service_v1" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace_v1.inosis_app.metadata[0].name
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

# 5. Ingress
resource "kubernetes_ingress_v1" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress"
    namespace = kubernetes_namespace_v1.inosis_app.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.nginx_static_ip.name
      "kubernetes.io/ingress.class"                 = "gce"
    }
  }

  spec {

    rule {
      http {
        # 1. KURAL: "/sayfa2" ile gelenler yeni uygulamaya gitsin
        path {
          path      = "/sayfa2"
          path_type = "Prefix"
          backend {
            service {
              name = "app2-service"
              port {
                number = 80
              }
            }
          }
        }

        # 2. KURAL: Diğer her şey (Ana sayfa "/") Vault'lu Nginx'e gitsin
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nginx-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
# App 2 Deployment
resource "kubernetes_deployment_v1" "app2" {
  metadata {
    name      = "inosis-app2"
    namespace = kubernetes_namespace_v1.inosis_app.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "app2"
      }
    }
    template {
      metadata {
        labels = {
          app = "app2"
        }
      }
      spec {
        # Yine aynı Node Pool'da çalışsın
        node_selector = {
          "cloud.google.com/gke-nodepool" = "inosis-app-pool-v2"
        }
        container {
          name  = "echo-container"
          # Ekrana sadece yazı basan basit bir test imajı
          image = "hashicorp/http-echo:latest"
          args  = ["-text= Burasi Sayfa 2 ingress", "-listen=:8080"]
          
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

# App 2 Service
resource "kubernetes_service_v1" "app2_service" {
  metadata {
    name      = "app2-service"
    namespace = kubernetes_namespace_v1.inosis_app.metadata[0].name
    annotations = {
      # Ingress'in ulaşabilmesi için NEG şart
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    selector = {
      app = "app2"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "NodePort" # Ingress için NodePort olmalı
  }
}