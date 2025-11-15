#!/bin/bash
set -e

# Variables
READONLY_APP_ID="2f83e2ca-2e7a-4fb3-800f-3284cc3e0d9b"
GITHUB_ORG="chiju"
GITHUB_REPO="aks-gitops-lab"
BRANCH_NAME=${1:-$(git branch --show-current)}

# Skip if it's the main branch
if [ "$BRANCH_NAME" = "main" ]; then
  echo "⚠️  Main branch already has full access"
  exit 0
fi

echo "🔐 Adding read-only access for branch: $BRANCH_NAME"

# Create federated credential for the specific branch
az ad app federated-credential create \
  --id $READONLY_APP_ID \
  --parameters '{
    "name": "'$BRANCH_NAME'-readonly",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/'$BRANCH_NAME'",
    "audiences": ["api://AzureADTokenExchange"]
  }' 2>/dev/null || echo "⚠️  Credential already exists for this branch"

echo "✅ Branch $BRANCH_NAME now has read-only terraform plan access!"
