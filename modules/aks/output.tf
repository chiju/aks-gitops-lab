output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "kube_config_raw" {
  description = "Raw Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration object (admin)"
  value       = azurerm_kubernetes_cluster.main.kube_config.0
  sensitive   = true
}

output "kube_config_user" {
  description = "Kubernetes configuration object (user)"
  value       = azurerm_kubernetes_cluster.main.kube_config_user.0
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}