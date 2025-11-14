output "namespace" {
  description = "ArgoCD namespace"
  value       = helm_release.argocd.namespace
}

output "release_name" {
  description = "ArgoCD Helm release name"
  value       = helm_release.argocd.name
}

output "chart_version" {
  description = "ArgoCD chart version deployed"
  value       = helm_release.argocd.version
}