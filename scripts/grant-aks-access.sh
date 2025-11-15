#!/bin/bash
set -e

# Variables
CLUSTER_NAME="aks-gitops-lab-aks"
RESOURCE_GROUP="aks-gitops-lab"
USER_EMAIL=${1:-$(az account show --query user.name -o tsv)}

echo "🔐 Granting AKS access to user: $USER_EMAIL"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Grant Azure Kubernetes Service Cluster Admin Role
echo "Granting cluster admin role..."
az role assignment create \
  --assignee "$USER_EMAIL" \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME"

# Get kubectl credentials
echo "Getting kubectl credentials..."
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --overwrite-existing

# Test access
echo "Testing kubectl access..."
kubectl get nodes

echo "✅ AKS access granted successfully!"
echo "You can now use kubectl to manage the cluster."
