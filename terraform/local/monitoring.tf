# ── Helm Provider ───────────────────────────────────────────
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "minikube"
  }
}

# ── Monitoring Namespace ────────────────────────────────────
resource "kubernetes_manifest" "monitoring_namespace" {
  manifest = yamldecode(file("${path.module}/../../manifests/namespaces/monitoring.yaml"))
}

# ── Prometheus + Grafana Stack ──────────────────────────────
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "58.2.2"

  set {
    name  = "grafana.adminPassword"
    value = "mlops123"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  depends_on = [kubernetes_manifest.monitoring_namespace]
}

resource "kubernetes_manifest" "servicemonitor" {
  manifest = yamldecode(file("${path.module}/../../manifests/monitoring/servicemonitor.yaml"))
  depends_on = [helm_release.prometheus_stack]
}