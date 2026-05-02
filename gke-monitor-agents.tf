# 1. GKE İçinde İzleme Ajanları İçin Karantina Odası
resource "kubernetes_namespace_v1" "monitoring_agents" {
  metadata {
    name = "monitoring"
  }
}

# 2. Prometheus Agent (GKE Metriklerini Okur, VM'e Fırlatır)
resource "helm_release" "prometheus_agent" {
  name       = "prometheus-agent"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace_v1.monitoring_agents.metadata[0].name
  version    = "25.11.0"

  # Çok Kritik: Agent modunu açıyoruz ve verileri senin VM'ine (Hub) yolluyoruz
  set {
    name  = "server.agentMode"
    value = "true" # GKE içinde disk doldurmaz, sadece iletir
  }
  set {
    name  = "server.remoteWrite[0].url"
    value = "http://34.56.65.76:9090/api/v1/write"
  }
}

# 3. Promtail (Loki'nin Resmi Log Ajanı - DaemonSet Modu)
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = kubernetes_namespace_v1.monitoring_agents.metadata[0].name
  version    = "6.16.1"

  # Logları doğrudan Hub'daki (Ubuntu VM) Loki'ye kargoluyoruz
  set {
    name  = "config.clients[0].url"
    value = "http://34.56.65.76:3100/loki/api/v1/push"
  }
}