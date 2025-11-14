terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate0c1d13fa"
    container_name       = "tfstate"
    key                  = "aks-gitops-lab.tfstate"
  }
}
