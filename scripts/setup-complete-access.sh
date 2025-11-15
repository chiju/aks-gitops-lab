#!/bin/bash
set -e

# Variables
GITHUB_ORG="chiju"
GITHUB_REPO="aks-gitops-lab"
FULL_ACCESS_APP="aks-gitops-lab-github"
READONLY_APP="aks-gitops-lab-readonly"

echo "🚀 Setting up complete Azure Workload Identity access..."

# Get subscription and tenant info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

# 1. Create Full Access App (Main Branch)
echo ""
echo "1️⃣ Creating full access application for main branch..."
FULL_APP_ID=$(az ad app create --display-name $FULL_ACCESS_APP --query appId -o tsv)
echo "Full Access App ID: $FULL_APP_ID"

az ad sp create --id $FULL_APP_ID

# Assign Contributor role
az role assignment create \
  --role Contributor \
  --assignee $FULL_APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Assign User Access Administrator role (needed for role assignments in Terraform)
az role assignment create \
  --role "User Access Administrator" \
  --assignee $FULL_APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID

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

# Assign Reader role
az role assignment create \
  --role Reader \
  --assignee $READONLY_APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Grant Storage Blob Data Reader access
STORAGE_ACCOUNT=$(grep 'storage_account_name' backend.tf | sed 's/.*= *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")
RESOURCE_GROUP=$(grep 'resource_group_name' backend.tf | sed 's/.*= *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")

if [ -n "$STORAGE_ACCOUNT" ] && [ -n "$RESOURCE_GROUP" ]; then
  echo "Granting Storage Blob Data Reader access..."
  az role assignment create \
    --assignee $READONLY_APP_ID \
    --role "Storage Blob Data Reader" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
  
  echo "Granting Storage Account Key Operator access for terraform init..."
  az role assignment create \
    --assignee $READONLY_APP_ID \
    --role "Storage Account Key Operator Service Role" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
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
echo "✅ Complete access setup finished!"
echo ""
echo "📋 Adding GitHub secrets automatically..."

# Get readonly SP object ID
READONLY_OBJECT_ID=$(az ad sp list --display-name $READONLY_APP --query "[0].id" -o tsv)

# Add all secrets
gh secret set AZURE_CLIENT_ID -b "$FULL_APP_ID"
gh secret set AZURE_CLIENT_ID_READONLY -b "$READONLY_APP_ID"
gh secret set AZURE_TENANT_ID -b "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID -b "$SUBSCRIPTION_ID"
gh secret set AZURE_READONLY_OBJECT_ID -b "$READONLY_OBJECT_ID"

echo "✅ GitHub secrets added!"
echo ""
echo "⚠️  You still need to add manually:"
echo "gh secret set GIT_USERNAME -b \"<your-github-username>\""
echo "gh secret set GIT_TOKEN -b \"<your-github-pat>\""
echo ""
echo "🚀 After adding GIT secrets, push to main to deploy!"
