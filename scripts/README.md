# Scripts Documentation

## Access Control Setup

This project uses a dual-credential approach for secure GitOps operations:

### 1. Full Access (Main Branch Only)
- **Script**: `setup-workload-identity.sh`
- **Permissions**: Contributor role
- **Usage**: Terraform apply operations on main branch
- **Secrets**: 
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID` 
  - `AZURE_SUBSCRIPTION_ID`

### 2. Read-Only Access (All Non-Main Branches)
- **Script**: `setup-readonly-access.sh`
- **Permissions**: Reader role + Storage Blob Data Reader
- **Usage**: Terraform plan operations on feature branches
- **Secrets**:
  - `AZURE_CLIENT_ID_READONLY`
  - `AZURE_TENANT_ID_READONLY`
  - `AZURE_SUBSCRIPTION_ID_READONLY`

## Setup Instructions

1. **Bootstrap Backend Storage**:
   ```bash
   ./scripts/bootstrap-backend.sh
   ```

2. **Setup Full Access (Main Branch)**:
   ```bash
   ./scripts/setup-workload-identity.sh
   ```

3. **Setup Read-Only Access (All Other Branches)**:
   ```bash
   ./scripts/setup-readonly-access.sh
   ```

4. **Add GitHub Secrets**:
   - Go to your repository settings
   - Add all 6 secrets from both scripts
   - The workflow will automatically use the correct credentials

## How It Works

### Terraform Plan Permissions
- **Read access** to Azure resources for comparison
- **Read access** to state file in storage account
- **No write access** needed (plan doesn't modify state)
- **No locking write access** needed (plan is read-only)

### Branch-Based Authentication
- **Main branch**: Uses full access credentials for apply operations
- **Feature branches**: Uses read-only credentials for plan operations
- **Pull requests**: Uses read-only credentials for plan operations

### Federated Credentials
- **Main branch**: Specific credential for `refs/heads/main`
- **All other branches**: Wildcard credential for `refs/heads/*`
- **Pull requests**: Specific credential for pull request events

## Legacy Script (Deprecated)
- `add-branch-credential.sh`: Adds individual branch access (no longer needed)

## Security Benefits
- ✅ No manual branch setup required
- ✅ Automatic read-only access for all feature branches
- ✅ Full access restricted to main branch only
- ✅ No service principal keys stored in GitHub
- ✅ Azure Workload Identity for secure authentication
