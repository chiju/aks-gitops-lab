# Scripts Documentation

## Access Control Setup

This project uses a dual-credential approach for secure GitOps operations:

### 1. Full Access (Main Branch Only)
- **Permissions**: Contributor role
- **Usage**: Terraform apply operations on main branch

### 2. Read-Only Access (Pull Requests)
- **Permissions**: Reader + Storage Account Key Operator + Storage Blob Data Reader
- **Usage**: Terraform plan operations on pull requests

## Setup Instructions

**For new repos, run just one script:**
```bash
./scripts/setup-complete-access.sh
```

This creates:
- ✅ Full access app for main branch
- ✅ Read-only app for pull requests
- ✅ All necessary role assignments
- ✅ Federated credentials

## GitHub Secrets Needed

Add these 4 secrets to your repository:
- `AZURE_CLIENT_ID` (full access)
- `AZURE_CLIENT_ID_READONLY` (read-only)
- `AZURE_TENANT_ID` (shared)
- `AZURE_SUBSCRIPTION_ID` (shared)

## How It Works

### Branch-Based Authentication
- **Main branch push**: Uses full access credentials for apply operations
- **Pull requests**: Uses read-only credentials for plan operations

### Security Benefits
- ✅ No manual branch setup required
- ✅ Automatic read-only access for all pull requests
- ✅ Full access restricted to main branch only
- ✅ No service principal keys stored in GitHub
- ✅ Azure Workload Identity for secure authentication
