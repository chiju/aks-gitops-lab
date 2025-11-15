terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatec9546223"
    container_name       = "tfstate"
    key                  = "aks-gitops-lab.tfstate"
  }
}
