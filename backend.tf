terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate65ec534e"
    container_name       = "tfstate"
    key                  = "aks-gitops-lab.tfstate"
  }
}
