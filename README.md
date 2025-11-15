# AKS GitOps Lab

Complete Azure Kubernetes Service (AKS) infrastructure with GitOps using ArgoCD, fully automated via GitHub Actions and Terraform.

## What Gets Deployed

- **Infrastructure**: AKS cluster, VNet, Resource Group
- **GitOps**: ArgoCD with app-of-apps pattern
- **Applications**: nginx, keda, prometheus monitoring, promtail
- **Automation**: Dual-credential CI/CD with GitHub Actions

## Prerequisites

- Azure CLI (`az login`)
- GitHub CLI (`gh auth login`)
- Terraform (v1.13.5+)
- kubectl
- Git

## Quick Start (3 Steps)

### 1. Bootstrap Backend

```bash
./scripts/bootstrap-backend.sh
```

**Output:** Storage account name (e.g., `tfstate27a151e5`)

**Action:** Update `backend.tf` with the storage account name:
```hcl
storage_account_name = "tfstate27a151e5"  # Use your output
```

### 2. Setup Service Principals

```bash
./scripts/setup-complete-access.sh
```

**What it does:**
- Creates 2 service principals (full-access + read-only)
- Assigns Azure roles (Contributor, User Access Administrator, Reader)
- Configures federated credentials for GitHub Actions
- **Automatically adds 5 GitHub secrets**

**Action:** Add 2 secrets manually:
```bash
gh secret set GIT_USERNAME -b "your-github-username"
gh secret set GIT_TOKEN -b "your-github-pat"
```

### 3. Deploy

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

**That's it!** GitHub Actions will:
- Run terraform plan
- Deploy AKS cluster
- Install ArgoCD
- Deploy all applications

## Architecture

### Dual-Credential Approach

**Pull Requests (Read-Only)**
- Service Principal: `aks-gitops-lab-readonly`
- Roles: Reader, Storage access, AKS Cluster Admin (read)
- Action: `terraform plan` only
- Purpose: Safe testing before merge

**Main Branch (Full-Access)**
- Service Principal: `aks-gitops-lab-github`
- Roles: Contributor, User Access Administrator
- Action: `terraform apply`
- Purpose: Deploy infrastructure

### GitOps Flow

```
PR → Plan (read-only) → Review → Merge → Apply (full-access) → ArgoCD syncs apps
```

## Project Structure

```
.
├── .github/workflows/
│   ├── terraform.yml      # Main CI/CD
│   └── destroy.yml        # Cleanup
├── apps/                  # Helm charts
│   ├── nginx/
│   ├── keda/
│   ├── kube-prometheus-stack/
│   └── promtail/
├── argocd-apps/          # ArgoCD applications
│   ├── nginx.yaml
│   ├── keda.yaml
│   ├── monitoring.yaml
│   └── promtail.yaml
├── modules/              # Terraform modules
│   ├── aks/
│   ├── argocd/
│   ├── resource-group/
│   └── vnet/
├── scripts/              # Setup scripts
│   ├── bootstrap-backend.sh
│   ├── setup-complete-access.sh
│   └── cleanup-all.sh
├── backend.tf
├── main.tf
└── README.md
```

## Adding Applications

1. Create Helm chart in `apps/your-app/`
2. Create ArgoCD app in `argocd-apps/your-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: your-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: apps/your-app
  destination:
    server: https://kubernetes.default.svc
    namespace: your-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

3. Commit and push - ArgoCD deploys automatically!

## Accessing the Cluster

```bash
# Get credentials
az aks get-credentials --resource-group aks-gitops-lab --name aks-gitops-lab-aks --admin

# Check cluster
kubectl get nodes
kubectl get pods -n argocd
kubectl get applications -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
# Username: admin
# Password: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

## Cleanup

```bash
# Complete cleanup (deletes everything)
./scripts/cleanup-all.sh
```

This removes:
- Service principals
- GitHub secrets
- Backend storage
- Resource groups
- Local state files

## Troubleshooting

### Issue: PR workflow fails with permission error
**Solution:** Ensure readonly SP has AKS Cluster Admin role (automated in Terraform)

### Issue: ArgoCD not syncing apps
**Solution:** 
- Check GitHub token: `kubectl get secret argocd-repo -n argocd -o yaml`
- Verify repo URL in `main.tf`

### Issue: Pods pending in monitoring namespace
**Solution:** Single node cluster has limited resources. Increase node count in `modules/aks/variables.tf`

## Permissions Explained

### Why Subscription-Level?

Terraform needs to create resource groups, which requires subscription-level permissions. Scoped permissions would require pre-existing resource groups, breaking automation.

### Full-Access Roles

- **Contributor**: Create/modify/delete resources
- **User Access Administrator**: Create role assignments (for readonly SP)

### Read-Only Roles

- **Reader**: Read all resources
- **Storage Blob Data Reader**: Read Terraform state
- **Storage Account Key Operator**: Initialize Terraform backend
- **AKS Cluster Admin**: Read cluster credentials for plan

## Cost

- **AKS**: 1 x Standard_B2s node (~$30/month)
- **Storage**: Standard_LRS (~$0.05/month)
- **Total**: ~$30-35/month

Destroy when not in use to save costs.

## Security Features

- ✅ Azure Workload Identity (OIDC)
- ✅ No stored credentials
- ✅ Federated authentication
- ✅ Separate read/write permissions
- ✅ Azure RBAC on AKS
- ✅ Encrypted Terraform state

## What's Automated

- ✅ Backend storage creation
- ✅ Service principal creation
- ✅ Role assignments
- ✅ GitHub secrets (5 of 7)
- ✅ AKS cluster deployment
- ✅ ArgoCD installation
- ✅ Application deployment
- ✅ Role assignments for readonly SP

## What's Manual

- ❌ Update backend.tf (one-time)
- ❌ Add GIT_USERNAME secret (one-time)
- ❌ Add GIT_TOKEN secret (one-time)

## License

MIT
