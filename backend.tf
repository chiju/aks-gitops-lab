terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate27a151e5"
    container_name       = "tfstate"
    key                  = "aks-gitops-lab.tfstate"
  }
}
