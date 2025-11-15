# Updated 2025-11-14T22:42:34
module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
}

module "vnet" {
  source = "./modules/vnet"

  name                = "${var.resource_group_name}-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
}

module "aks" {
  source = "./modules/aks"

  name                = "${var.resource_group_name}-aks"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.resource_group_name
  subnet_id           = module.vnet.aks_subnet_id
  kubernetes_version  = var.kubernetes_version
}

# Data source to ensure cluster is ready
data "azurerm_kubernetes_cluster" "main" {
  name                = module.aks.cluster_name
  resource_group_name = module.resource_group.name

  depends_on = [module.aks]
}

# Azure RBAC role assignment for read-only service principal
resource "azurerm_role_assignment" "aks_cluster_user_readonly" {
  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = "7f4dcf37-afb5-4049-a9cd-ad6c620bfb68" # Read-only service principal object ID
}

module "argocd" {
  source = "./modules/argocd"

  namespace           = "argocd"
  argocd_version      = "9.1.3"
  git_repo_url        = "https://github.com/chiju/aks-gitops-lab.git"
  git_target_revision = "main"
  git_apps_path       = "argocd-apps"
  github_username     = var.github_username
  github_token        = var.github_token

  depends_on = [data.azurerm_kubernetes_cluster.main, azurerm_role_assignment.aks_cluster_user_readonly]
} # Updated Fri Nov 14 22:18:12 CET 2025
# Trigger workflow Fri Nov 14 22:35:21 CET 2025
