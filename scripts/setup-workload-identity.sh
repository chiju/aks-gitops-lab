#!/bin/bash
set -e

# Variables - UPDATE THESE
GITHUB_ORG="chiju"  # Your GitHub username/org
GITHUB_REPO="aks-gitops-lab"
APP_NAME="aks-gitops-lab-github"

echo "🔐 Setting up Azure Workload Identity for GitHub Actions..."

# Create Azure AD Application
echo "Creating Azure AD Application..."
APP_ID=$(az ad app create --display-name $APP_NAME --query appId -o tsv)
echo "App ID: $APP_ID"

# Create Service Principal
echo "Creating Service Principal..."
az ad sp create --id $APP_ID

# Get subscription and tenant info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

# Assign Contributor role
echo "Assigning Contributor role..."
az role assignment create \
  --role Contributor \
  --assignee $APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Create federated credential for main branch
echo "Creating federated credential for main branch..."
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests
echo "Creating federated credential for pull requests..."
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo "✅ Workload Identity setup complete!"
echo ""
echo "Add these secrets to your GitHub repository:"
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Note: TENANT_ID and SUBSCRIPTION_ID will be shared with read-only setup"
echo ""
echo "Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
