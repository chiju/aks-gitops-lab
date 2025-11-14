resource "helm_release" "argocd" {
  name      = "argocd"
  chart     = "oci://ghcr.io/argoproj/argo-helm/argo-cd"
  namespace = var.namespace
  version   = var.chart_version

  create_namespace = true

  set = [
    {
      name  = "server.service.type"
      value = var.service_type
    }
  ]
}