terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate7bd65d9f"
    container_name       = "tfstate"
    key                  = "aks-gitops-lab.tfstate"
  }
}
