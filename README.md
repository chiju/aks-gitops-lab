# AKS GitOps Lab

Complete Azure Kubernetes Service (AKS) infrastructure with GitOps using ArgoCD, fully automated via GitHub Actions and Terraform.

## Architecture

- **Infrastructure as Code**: Terraform with modular design
- **GitOps**: ArgoCD with app-of-apps pattern
- **CI/CD**: GitHub Actions with dual-credential approach
- **Security**: Azure Workload Identity, Azure RBAC, no stored secrets

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- GitHub CLI installed and logged in (`gh auth login`)
- Terraform installed (v1.13.5+)
- kubectl installed
- Git configured

## Quick Start

### 1. Bootstrap Backend (One-time)

```bash
./scripts/bootstrap-backend.sh
```

This creates:
- Resource group: `terraform-state-rg`
- Storage account: `tfstate<random>`
- Container: `tfstate`

**Action Required:** Update `backend.tf` with the storage account name from output.

### 2. Setup Service Principals (One-time)

```bash
./scripts/setup-complete-access.sh
```

This creates and configures:
- Full access service principal (main branch)
  - Contributor at subscription level
  - Federated credential for main branch
- Read-only service principal (PRs)
  - Reader at subscription level
  - Storage access for state
  - Federated credential for pull requests
- **Automatically adds 5 GitHub secrets**

**Action Required:** Add these 2 GitHub secrets manually:

```bash
gh secret set GIT_USERNAME -b "<your-github-username>"
gh secret set GIT_TOKEN -b "<your-github-pat>"
```

### 3. Deploy via GitOps Workflow

**Option A: Test with PR first (Recommended)**

```bash
# Create feature branch
git checkout -b feature/test-deployment

# Make a change (e.g., update a tag in modules/aks/main.tf)
git add .
git commit -m "Test deployment"
git push -u origin feature/test-deployment

# Create PR
gh pr create --title "Test deployment" --body "Testing infrastructure"

# PR workflow runs with read-only credentials (plan only)
# Review the plan in PR comments

# Merge to deploy
gh pr merge --squash --delete-branch
```

**Option B: Direct to main**

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

## What Gets Deployed

### Infrastructure (Terraform)
- Resource group: `aks-gitops-lab`
- VNet with subnet
- AKS cluster (1 node, Kubernetes 1.34)
- ArgoCD (Helm chart)

### GitOps (ArgoCD)
- App-of-apps pattern configured
- Automatic sync enabled
- Applications from `argocd-apps/` directory

## CI/CD Workflow

### Pull Requests
- ✅ Security scan (Trivy)
- ✅ Terraform plan (read-only credentials)
- ✅ Plan posted as PR comment
- ❌ No apply

### Main Branch
- ✅ Security scan
- ✅ Terraform plan
- ✅ Terraform apply (full credentials)
- ✅ Post-deployment tests

## Project Structure

```
.
├── .github/workflows/
│   ├── terraform.yml      # Main CI/CD workflow
│   └── destroy.yml        # Destroy infrastructure
├── argocd-apps/           # ArgoCD application manifests
│   ├── example-app.yaml
│   └── README.md
├── modules/               # Terraform modules
│   ├── aks/
│   ├── argocd/
│   ├── resource-group/
│   └── vnet/
├── scripts/               # Bootstrap scripts
│   ├── bootstrap-backend.sh
│   ├── setup-complete-access.sh
│   ├── add-branch-access.sh
│   └── grant-aks-access.sh
├── backend.tf            # Terraform backend config
├── main.tf               # Main Terraform config
├── provider.tf           # Provider configuration
├── variables.tf          # Input variables
└── outputs.tf            # Output values
```

## Adding Applications

Add ArgoCD application manifests to `argocd-apps/`:

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
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Commit and push - ArgoCD will automatically deploy!

## Accessing the Cluster

```bash
# Get kubectl credentials
az aks get-credentials --resource-group aks-gitops-lab --name aks-gitops-lab-aks --admin

# Check cluster
kubectl get nodes

# Check ArgoCD
kubectl get pods -n argocd
kubectl get applications -n argocd
```

## Destroying Infrastructure

```bash
# Via GitHub Actions
gh workflow run destroy.yml -f confirm=destroy

# Or locally
terraform destroy \
  -var="subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var="github_username=$GIT_USERNAME" \
  -var="github_token=$GIT_TOKEN"
```

## Permissions Model

### Full Access (Main Branch)
- **Role**: Contributor at subscription level
- **Purpose**: Create/modify/delete any resource
- **Usage**: Terraform apply on main branch
- **Why subscription-level**: Terraform needs to create resource groups

### Read-Only (Pull Requests)
- **Role**: Reader at subscription level
- **Purpose**: Read resources for terraform plan
- **Usage**: Terraform plan on PRs
- **Additional**: Storage access for state file

## Security Features

- ✅ Azure Workload Identity (no stored credentials)
- ✅ Federated credentials (OIDC)
- ✅ Azure RBAC enabled on AKS
- ✅ Separate credentials for read/write
- ✅ Security scanning with Trivy
- ✅ Terraform state encryption
- ✅ Admin credentials for automation

## Troubleshooting

### Issue: Terraform plan fails with subscription error
**Solution**: Ensure `AZURE_SUBSCRIPTION_ID` secret is set correctly

### Issue: ArgoCD not syncing applications
**Solution**: 
- Check GitHub token has repo access
- Verify `git_repo_url` in main.tf is correct
- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server`

### Issue: kubectl access denied
**Solution**: Use admin credentials:
```bash
az aks get-credentials --resource-group aks-gitops-lab --name aks-gitops-lab-aks --admin
```

### Issue: Pipeline fails on resource group creation
**Solution**: Resource group already exists. Either:
- Delete it: `az group delete --name aks-gitops-lab --yes`
- Or import it into Terraform state

## Advanced Configuration

### Change Kubernetes Version

Edit `variables.tf`:
```hcl
variable "kubernetes_version" {
  default     = "1.35"  # Update version
}
```

### Add Admin Group

Edit `variables.tf`:
```hcl
variable "aks_admin_group_object_ids" {
  default     = ["<azure-ad-group-object-id>"]
}
```

### Change Node Count

Edit `modules/aks/variables.tf`:
```hcl
variable "node_count" {
  default     = 3  # Increase nodes
}
```

## Cost Optimization

- Default: 1 x Standard_B2s node (~$30/month)
- Storage: Standard_LRS (~$0.05/month)
- Total: ~$30-35/month

To reduce costs:
- Use smaller VM size
- Destroy when not in use

## Production Considerations

1. **Scoped Permissions**: Consider scoping to resource groups after initial setup
2. **Monitoring**: Enable Azure Monitor for containers
3. **Backup**: Enable AKS backup for etcd
4. **Network Policies**: Implement Kubernetes network policies
5. **Pod Security**: Enable Pod Security Standards
6. **Multi-Environment**: Create separate resource groups per environment

## License

MIT
