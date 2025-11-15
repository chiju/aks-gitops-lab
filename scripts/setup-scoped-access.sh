#!/bin/bash
set -e

# Variables
GITHUB_ORG="chiju"
GITHUB_REPO="aks-gitops-lab"
FULL_ACCESS_APP="aks-gitops-lab-github"
READONLY_APP="aks-gitops-lab-readonly"
MAIN_RG="aks-gitops-lab"
STATE_RG="terraform-state-rg"

echo "🚀 Setting up scoped Azure Workload Identity access..."

# Get subscription and tenant info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

# Ensure resource groups exist
echo ""
echo "📦 Ensuring resource groups exist..."
az group create --name $MAIN_RG --location westeurope --output none 2>/dev/null || echo "RG $MAIN_RG already exists"
az group show --name $STATE_RG --output none 2>/dev/null || {
  echo "❌ State resource group $STATE_RG does not exist!"
  echo "Run ./scripts/bootstrap-backend.sh first"
  exit 1
}

# 1. Create Full Access App (Main Branch)
echo ""
echo "1️⃣ Creating full access application for main branch..."
FULL_APP_ID=$(az ad app create --display-name $FULL_ACCESS_APP --query appId -o tsv)
echo "Full Access App ID: $FULL_APP_ID"

az ad sp create --id $FULL_APP_ID

# Assign scoped Contributor roles
echo "Assigning Contributor on $MAIN_RG..."
az role assignment create \
  --role Contributor \
  --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$MAIN_RG"

echo "Assigning Contributor on $STATE_RG..."
az role assignment create \
  --role Contributor \
  --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$STATE_RG"

echo "Assigning Network Contributor on $MAIN_RG..."
az role assignment create \
  --role "Network Contributor" \
  --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$MAIN_RG"

# Create federated credential for main branch
az ad app federated-credential create \
  --id $FULL_APP_ID \
  --parameters '{
    "name": "main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 2. Create Read-Only App (Feature Branches)
echo ""
echo "2️⃣ Creating read-only application for feature branches..."
READONLY_APP_ID=$(az ad app create --display-name $READONLY_APP --query appId -o tsv)
echo "Read-Only App ID: $READONLY_APP_ID"

az ad sp create --id $READONLY_APP_ID

# Assign scoped Reader roles
echo "Assigning Reader on $MAIN_RG..."
az role assignment create \
  --role Reader \
  --assignee $READONLY_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$MAIN_RG"

echo "Assigning Reader on $STATE_RG..."
az role assignment create \
  --role Reader \
  --assignee $READONLY_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$STATE_RG"

# Grant Storage permissions
STORAGE_ACCOUNT=$(grep 'storage_account_name' backend.tf | sed 's/.*= *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")

if [ -n "$STORAGE_ACCOUNT" ]; then
  echo "Granting Storage Blob Data Reader access..."
  az role assignment create \
    --assignee $READONLY_APP_ID \
    --role "Storage Blob Data Reader" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$STATE_RG/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
  
  echo "Granting Storage Account Key Operator access..."
  az role assignment create \
    --assignee $READONLY_APP_ID \
    --role "Storage Account Key Operator Service Role" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$STATE_RG/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
else
  echo "⚠️  Could not find storage account info in backend.tf"
fi

# Create federated credential for pull requests
az ad app federated-credential create \
  --id $READONLY_APP_ID \
  --parameters '{
    "name": "pull-requests-readonly",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo ""
echo "✅ Scoped access setup complete!"
echo ""
echo "📋 Permissions Summary:"
echo ""
echo "Full Access SP (Main Branch):"
echo "  - Contributor on: $MAIN_RG"
echo "  - Contributor on: $STATE_RG"
echo "  - Network Contributor on: $MAIN_RG"
echo ""
echo "Read-Only SP (PRs):"
echo "  - Reader on: $MAIN_RG"
echo "  - Reader on: $STATE_RG"
echo "  - Storage Blob Data Reader on: $STORAGE_ACCOUNT"
echo "  - Storage Account Key Operator on: $STORAGE_ACCOUNT"
echo ""
echo "📋 Add these 4 GitHub secrets:"
echo "AZURE_CLIENT_ID: $FULL_APP_ID"
echo "AZURE_CLIENT_ID_READONLY: $READONLY_APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
