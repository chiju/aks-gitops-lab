#!/bin/bash
set -e

# Variables
APP_ID="3033c418-1842-4eac-bba4-07c6d22f4e15"
GITHUB_ORG="chiju"
GITHUB_REPO="aks-gitops-lab"
BRANCH_NAME=${1:-$(git branch --show-current)}

echo "🔐 Adding federated credential for branch: $BRANCH_NAME"

# Create federated credential for the branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "'$BRANCH_NAME'-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/'$BRANCH_NAME'",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo "✅ Federated credential added for branch: $BRANCH_NAME"
echo "GitHub Actions can now authenticate from this branch!"
