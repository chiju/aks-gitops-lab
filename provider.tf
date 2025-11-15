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
    host = "https://${var.resource_group_name}-aks.hcp.westeurope.azmk8s.io"
    
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
  host = "https://${var.resource_group_name}-aks.hcp.westeurope.azmk8s.io"
  
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