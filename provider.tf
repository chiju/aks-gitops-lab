# Fixed service principal permissions for Helm
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
    host                   = module.aks.kube_config.host
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/__internal"
      command     = "az"
      args = [
        "aks",
        "get-credentials",
        "--resource-group", "aks-gitops-lab",
        "--name", "aks-gitops-lab-aks",
        "--format", "exec"
      ]
    }
  }
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/__internal"
    command     = "az"
    args = [
      "aks",
      "get-credentials",
      "--resource-group", "aks-gitops-lab",
      "--name", "aks-gitops-lab-aks",
      "--format", "exec"
    ]
  }
}