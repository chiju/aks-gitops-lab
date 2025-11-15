#!/bin/bash
set -e

# Variables
GITHUB_ORG="chiju"
GITHUB_REPO="aks-gitops-lab"
APP_NAME="aks-gitops-lab-readonly"

echo "🔐 Setting up read-only Azure Workload Identity for non-main branches..."

# Create Azure AD Application for read-only access
echo "Creating read-only Azure AD Application..."
READONLY_APP_ID=$(az ad app create --display-name $APP_NAME --query appId -o tsv)
echo "Read-only App ID: $READONLY_APP_ID"

# Create Service Principal
echo "Creating Service Principal..."
az ad sp create --id $READONLY_APP_ID

# Get subscription and tenant info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

# Assign Reader role (read-only)
echo "Assigning Reader role..."
az role assignment create \
  --role Reader \
  --assignee $READONLY_APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Get storage account name from backend.tf
STORAGE_ACCOUNT=$(grep 'storage_account_name' backend.tf | sed 's/.*= *"\([^"]*\)".*/\1/')
RESOURCE_GROUP=$(grep 'resource_group_name' backend.tf | sed 's/.*= *"\([^"]*\)".*/\1/')

if [ -n "$STORAGE_ACCOUNT" ] && [ -n "$RESOURCE_GROUP" ]; then
  echo "Granting Storage Blob Data Reader access to state file..."
  az role assignment create \
    --assignee $READONLY_APP_ID \
    --role "Storage Blob Data Reader" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
else
  echo "⚠️  Could not find storage account info in backend.tf"
  echo "Manually grant 'Storage Blob Data Reader' role to the service principal"
fi

# Create federated credential for all non-main branches using wildcard pattern
echo "Creating federated credential for all non-main branches..."
az ad app federated-credential create \
  --id $READONLY_APP_ID \
  --parameters '{
    "name": "non-main-branches",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/*",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests
echo "Creating federated credential for pull requests..."
az ad app federated-credential create \
  --id $READONLY_APP_ID \
  --parameters '{
    "name": "pull-requests-readonly",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo "✅ Read-only Workload Identity setup complete!"
echo ""
echo "Add this additional secret to your GitHub repository:"
echo "AZURE_CLIENT_ID_READONLY: $READONLY_APP_ID"
echo ""
echo "Note: Use the same AZURE_TENANT_ID and AZURE_SUBSCRIPTION_ID from the main setup"
echo ""
echo "The read-only credentials will work for:"
echo "- All branches except main (terraform plan only)"
echo "- Pull requests (terraform plan only)"
echo ""
echo "Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
