# Minimum Permissions Guide

## Current Setup (Working but Broad)

**Full Access SP (Main Branch):**
- ✅ Contributor at subscription level
- ⚠️ Can create/modify/delete ANY resource in subscription

**Read-Only SP (PRs):**
- ✅ Reader at subscription level
- ✅ Storage Blob Data Reader (scoped to storage account)
- ✅ Storage Account Key Operator (scoped to storage account)
- ⚠️ Can read ALL resources in subscription

## Minimum Permissions (Production Ready)

### Prerequisites
Resource groups must exist before scoping permissions:
```bash
az group create --name aks-gitops-lab --location westeurope
az group create --name terraform-state-rg --location westeurope
```

### Full Access SP (Main Branch)

**Remove subscription-level:**
```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
FULL_APP_ID="3033c418-1842-4eac-bba4-07c6d22f4e15"

az role assignment delete \
  --assignee $FULL_APP_ID \
  --role Contributor \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

**Add resource group-level:**
```bash
# Main resource group
az role assignment create \
  --role Contributor \
  --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aks-gitops-lab"

# State resource group
az role assignment create \
  --role Contributor \
  --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/terraform-state-rg"

# Network operations
az role assignment create \
  --role "Network Contributor" \
  --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aks-gitops-lab"
```

### Read-Only SP (PRs)

**Remove subscription-level:**
```bash
READONLY_APP_ID="2f83e2ca-2e7a-4fb3-800f-3284cc3e0d9b"

az role assignment delete \
  --assignee $READONLY_APP_ID \
  --role Reader \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

**Add resource group-level:**
```bash
# Main resource group
az role assignment create \
  --role Reader \
  --assignee $READONLY_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aks-gitops-lab"

# State resource group
az role assignment create \
  --role Reader \
  --assignee $READONLY_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/terraform-state-rg"

# Storage permissions already scoped correctly
```

## Automated Script

Create `scripts/scope-permissions.sh`:

```bash
#!/bin/bash
set -e

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
FULL_APP_ID="3033c418-1842-4eac-bba4-07c6d22f4e15"
READONLY_APP_ID="2f83e2ca-2e7a-4fb3-800f-3284cc3e0d9b"

echo "🔒 Scoping permissions to resource groups..."

# Remove subscription-level
echo "Removing subscription-level permissions..."
az role assignment delete --assignee $FULL_APP_ID --role Contributor --scope "/subscriptions/$SUBSCRIPTION_ID" || true
az role assignment delete --assignee $READONLY_APP_ID --role Reader --scope "/subscriptions/$SUBSCRIPTION_ID" || true

# Add scoped permissions
echo "Adding resource group-level permissions..."

# Full Access
az role assignment create --role Contributor --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aks-gitops-lab"
az role assignment create --role Contributor --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/terraform-state-rg"
az role assignment create --role "Network Contributor" --assignee $FULL_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aks-gitops-lab"

# Read-Only
az role assignment create --role Reader --assignee $READONLY_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aks-gitops-lab"
az role assignment create --role Reader --assignee $READONLY_APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/terraform-state-rg"

echo "✅ Permissions scoped successfully!"
```

## When to Apply

**Safe to apply when:**
- ✅ Infrastructure is destroyed (no active resources)
- ✅ Resource groups exist
- ✅ You have time to troubleshoot if needed

**Risk:**
- If resource groups don't exist, Terraform can't create them
- May need to manually create resource groups first

## Testing Approach

1. **Test in PR first:**
   - Scope permissions
   - Create PR with small change
   - Verify plan works
   
2. **If plan works:**
   - Merge to main
   - Verify apply works

3. **If issues:**
   - Revert to subscription-level temporarily
   - Debug specific permission needed
   - Re-scope with additional permission

## Comparison

| Aspect | Current (Broad) | Minimum (Scoped) |
|--------|----------------|------------------|
| Security | ⚠️ Can access all resources | ✅ Only specific RGs |
| Setup | ✅ Simple | ⚠️ RGs must exist first |
| Flexibility | ✅ Can create any resource | ⚠️ Limited to RGs |
| Production | ❌ Not recommended | ✅ Best practice |
| Lab/Demo | ✅ Fine | ⚠️ Overkill |

## Recommendation

**For Lab/Demo:** Keep current setup (working and simple)

**For Production:** Apply minimum permissions after initial setup

**Hybrid Approach:** 
- Use broad permissions for initial setup
- Scope down after infrastructure is stable
- Document the scoped permissions for future reference
