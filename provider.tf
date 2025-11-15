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
    host                   = try(module.aks.kube_config.host, null)
    client_certificate     = try(base64decode(module.aks.kube_config.client_certificate), null)
    client_key             = try(base64decode(module.aks.kube_config.client_key), null)
    cluster_ca_certificate = try(base64decode(module.aks.kube_config.cluster_ca_certificate), null)
  }
}

provider "kubernetes" {
  host                   = try(module.aks.kube_config.host, null)
  client_certificate     = try(base64decode(module.aks.kube_config.client_certificate), null)
  client_key             = try(base64decode(module.aks.kube_config.client_key), null)
  cluster_ca_certificate = try(base64decode(module.aks.kube_config.cluster_ca_certificate), null)
}