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
  kubernetes = length(try(module.aks.kube_config.host, "")) > 0 ? {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  } : {
    config_path = "/dev/null"
  }
}

provider "kubernetes" {
  config_path = length(try(module.aks.kube_config.host, "")) > 0 ? "" : "/dev/null"
  host                   = try(module.aks.kube_config.host, "")
  client_certificate     = try(base64decode(module.aks.kube_config.client_certificate), "")
  client_key             = try(base64decode(module.aks.kube_config.client_key), "")
  cluster_ca_certificate = try(base64decode(module.aks.kube_config.cluster_ca_certificate), "")
}