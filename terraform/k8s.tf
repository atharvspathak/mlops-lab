# ── Kubernetes Provider ─────────────────────────────────────
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_manifest" "namespace_mlops" {
  manifest = yamldecode(file("${path.module}/../manifests/namespaces/mlops.yaml"))
}

resource "kubernetes_manifest" "deployment" {
  manifest   = yamldecode(file("${path.module}/../manifests/app/deployment.yaml"))
  depends_on = [kubernetes_manifest.namespace_mlops]
}

resource "kubernetes_manifest" "service" {
  manifest   = yamldecode(file("${path.module}/../manifests/app/service.yaml"))
  depends_on = [kubernetes_manifest.namespace_mlops]
}