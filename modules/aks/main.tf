resource "azurerm_kubernetes_cluster" "main" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  oidc_issuer_enabled               = true
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Purpose     = "GitOps-Demo"
  }
}

# Role assignments for readonly SP

# Grant read-only SP access to cluster credentials for terraform plan
resource "azurerm_role_assignment" "readonly_cluster_user" {
  count                = var.readonly_client_id != "" ? 1 : 0
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.readonly_client_id
}

resource "azurerm_role_assignment" "readonly_cluster_admin" {
  count                = var.readonly_client_id != "" ? 1 : 0
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = var.readonly_client_id
} # Test prometheus deployment
# Add promtail for log collection
