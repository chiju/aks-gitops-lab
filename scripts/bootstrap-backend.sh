#!/bin/bash
set -e

# Variables
RESOURCE_GROUP="terraform-state-rg"
LOCATION="westeurope"
STORAGE_ACCOUNT="tfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"

echo "🚀 Bootstrapping Terraform backend..."
echo "Storage Account: $STORAGE_ACCOUNT"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

echo "✅ Backend created successfully!"
echo ""
echo "Add this to your terraform/backend.tf:"
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"aks-gitops-lab.tfstate\""
echo "  }"
echo "}"
