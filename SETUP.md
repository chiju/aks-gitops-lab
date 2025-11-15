# Complete Setup Guide - From Scratch

This guide walks through setting up the entire AKS GitOps infrastructure in a new Azure account and GitHub repository.

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- GitHub CLI installed and logged in (`gh auth login`)
- Terraform installed (v1.13.5+)
- kubectl installed
- Git configured

## Step 1: Fork/Clone Repository

```bash
# Clone or fork this repository
git clone https://github.com/YOUR_ORG/aks-gitops-lab.git
cd aks-gitops-lab
```

## Step 2: Update Configuration

Edit these files with your values:

**`scripts/setup-complete-access.sh`:**
```bash
GITHUB_ORG="your-org"
GITHUB_REPO="your-repo-name"
```

**`backend.tf`:**
- Will be created by bootstrap script

## Step 3: Bootstrap Terraform Backend

```bash
./scripts/bootstrap-backend.sh
```

This creates:
- Resource group: `terraform-state-rg`
- Storage account: `tfstate<random>`
- Container: `tfstate`

**Action Required:** Update `backend.tf` with the output values.

## Step 4: Setup Azure Service Principals

```bash
./scripts/setup-complete-access.sh
```

This creates:
- Full access service principal (main branch)
- Read-only service principal (PRs)
- Federated credentials for GitHub Actions
- Role assignments

**Action Required:** Add these 4 secrets to GitHub:
- `AZURE_CLIENT_ID` (from script output)
- `AZURE_CLIENT_ID_READONLY` (from script output)
- `AZURE_TENANT_ID` (from script output)
- `AZURE_SUBSCRIPTION_ID` (from script output)

```bash
# Add secrets via GitHub CLI
gh secret set AZURE_CLIENT_ID -b "xxx"
gh secret set AZURE_CLIENT_ID_READONLY -b "xxx"
gh secret set AZURE_TENANT_ID -b "xxx"
gh secret set AZURE_SUBSCRIPTION_ID -b "xxx"
```

## Step 5: Add GitHub Token for ArgoCD

```bash
# Create GitHub personal access token with repo access
# Then add to secrets:
gh secret set GIT_TOKEN -b "ghp_xxx"
gh secret set GIT_USERNAME -b "your-username"
```

## Step 6: Update Terraform Variables

**`variables.tf`:**
- Update defaults if needed (resource group name, location, etc.)

**`main.tf`:**
- Update `git_repo_url` to your repository

## Step 7: Initial Deployment

```bash
# Commit and push to main branch
git add .
git commit -m "Initial setup"
git push origin main
```

This triggers the GitHub Actions workflow which will:
1. Run security scan
2. Run terraform plan
3. Run terraform apply (creates AKS + ArgoCD)
4. Run post-deployment tests

## Step 8: Get AKS Access

```bash
# After deployment completes
./scripts/grant-aks-access.sh your-email@domain.com
```

This grants you kubectl access to the cluster.

## Step 9: Verify Deployment

```bash
# Check cluster
kubectl get nodes

# Check ArgoCD
kubectl get pods -n argocd

# Check applications
kubectl get applications -n argocd
```

## Step 10: Deploy Applications via GitOps

Add application manifests to `argocd-apps/` directory:

```yaml
# argocd-apps/my-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_ORG/YOUR_REPO.git
    targetRevision: main
    path: my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Commit and push - ArgoCD will automatically deploy!

## Optional: Add Branch Access

For new feature branches that need plan access:

```bash
./scripts/add-branch-access.sh feature-branch-name
```

## Cleanup

To destroy all infrastructure:

```bash
# Via GitHub Actions
gh workflow run destroy.yml -f confirm=destroy

# Or locally
terraform destroy
```

## Architecture Summary

**CI/CD Flow:**
- PRs → Plan with read-only credentials
- Main branch → Apply with full credentials

**GitOps Flow:**
- Changes to `argocd-apps/*.yaml` → ArgoCD auto-syncs
- No Terraform needed for app deployments

**Security:**
- Azure Workload Identity (no stored credentials)
- Subscription-level permissions (scope down for production)
- Azure RBAC enabled on AKS
- Separate credentials for read/write operations

## Troubleshooting

**Issue: Terraform plan fails with subscription error**
- Ensure `AZURE_SUBSCRIPTION_ID` secret is set
- Check service principal has correct permissions

**Issue: ArgoCD not syncing**
- Check GitHub token has repo access
- Verify `git_repo_url` in main.tf is correct

**Issue: kubectl access denied**
- Run `./scripts/grant-aks-access.sh your-email@domain.com`
- Or use admin credentials: `az aks get-credentials --admin`

## Production Considerations

1. **Scope Permissions:** Change from subscription-level to resource group-level
2. **Enable Monitoring:** Add Azure Monitor for containers
3. **Setup Alerts:** Configure alerts for cluster health
4. **Backup:** Enable AKS backup for etcd
5. **Network Policies:** Implement Kubernetes network policies
6. **Pod Security:** Enable Pod Security Standards
7. **Cost Management:** Set up budget alerts
8. **Multi-Environment:** Create separate resource groups per environment
