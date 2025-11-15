terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatebc11c227"
    container_name       = "tfstate"
    key                  = "aks-gitops-lab.tfstate"
  }
}
