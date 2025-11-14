terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.52.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = "d2c2211d-193c-47e7-8247-85465d5ff1a6"
  resource_provider_registrations = "none"
}