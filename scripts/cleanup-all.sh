#!/bin/bash
set -e

echo "🧹 Complete cleanup - deleting everything..."

# Get IDs
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
FULL_APP=$(az ad app list --display-name "aks-gitops-lab-github" --query "[0].appId" -o tsv)
READONLY_APP=$(az ad app list --display-name "aks-gitops-lab-readonly" --query "[0].appId" -o tsv)
STORAGE_ACCOUNT=$(grep 'storage_account_name' backend.tf | sed 's/.*= *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")

# Delete GitHub secrets
echo "Deleting GitHub secrets..."
gh secret delete AZURE_CLIENT_ID --repo chiju/aks-gitops-lab || true
gh secret delete AZURE_CLIENT_ID_READONLY --repo chiju/aks-gitops-lab || true
gh secret delete AZURE_TENANT_ID --repo chiju/aks-gitops-lab || true
gh secret delete AZURE_SUBSCRIPTION_ID --repo chiju/aks-gitops-lab || true
gh secret delete AZURE_READONLY_OBJECT_ID --repo chiju/aks-gitops-lab || true
gh secret delete GIT_USERNAME --repo chiju/aks-gitops-lab || true
gh secret delete GIT_TOKEN --repo chiju/aks-gitops-lab || true

# Delete service principals
if [ -n "$FULL_APP" ]; then
  echo "Deleting full-access app..."
  az ad app delete --id $FULL_APP
fi

if [ -n "$READONLY_APP" ]; then
  echo "Deleting readonly app..."
  az ad app delete --id $READONLY_APP
fi

# Delete backend storage (includes remote state file)
if [ -n "$STORAGE_ACCOUNT" ]; then
  echo "Deleting backend storage..."
  az group delete --name terraform-state-rg --yes --no-wait
fi

# Delete local Terraform state and cache
echo "Cleaning local Terraform files..."
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

# Delete resource group (if exists)
RG_EXISTS=$(az group exists --name aks-gitops-lab)
if [ "$RG_EXISTS" = "true" ]; then
  echo "Deleting resource group..."
  az group delete --name aks-gitops-lab --yes --no-wait
else
  echo "Resource group already deleted"
fi

echo "✅ Cleanup complete!"
echo ""
echo "To start fresh, run:"
echo "1. ./scripts/bootstrap-backend.sh"
echo "2. Update backend.tf with new storage account"
echo "3. ./scripts/setup-complete-access.sh"
echo "4. Add GIT_USERNAME and GIT_TOKEN secrets"
echo "5. git push origin main"
