terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.53.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = "d2c2211d-193c-47e7-8247-85465d5ff1a6"
  resource_provider_registrations = "none"
}

provider "helm" {
  kubernetes = {
    host                   = try(data.azurerm_kubernetes_cluster.main.fqdn, "")
    cluster_ca_certificate = try(base64decode(data.azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate), "")
    
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "az"
      args = [
        "aks",
        "get-credentials",
        "--resource-group", var.resource_group_name,
        "--name", "${var.resource_group_name}-aks",
        "--format", "exec"
      ]
    }
  }
}

provider "kubernetes" {
  host                   = try(data.azurerm_kubernetes_cluster.main.fqdn, "")
  cluster_ca_certificate = try(base64decode(data.azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate), "")
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "az"
    args = [
      "aks",
      "get-credentials",
      "--resource-group", var.resource_group_name,
      "--name", "${var.resource_group_name}-aks",
      "--format", "exec"
    ]
  }
}