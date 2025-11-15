# AKS GitOps Lab

Production-ready Azure Kubernetes Service (AKS) infrastructure with GitOps using ArgoCD, fully automated via GitHub Actions and Terraform.

## 🚀 From Scratch to Production

This project demonstrates a **complete GitOps workflow** from zero to a fully automated Kubernetes cluster:

1. **Bootstrap** → Create backend storage for Terraform state
2. **Setup** → Configure service principals with OIDC authentication
3. **Deploy** → Push to GitHub, infrastructure deploys automatically
4. **GitOps** → ArgoCD syncs applications from Git every 30 seconds
5. **Scale** → KEDA autoscales based on CPU/memory metrics
6. **Monitor** → Prometheus + Grafana for metrics, Loki for logs
7. **Cleanup** → One command destroys everything

**Total setup time:** ~20 minutes (mostly waiting for AKS cluster)

**Manual steps:** Only 3 (bootstrap, update config, add 2 secrets)

**Everything else:** Fully automated via GitHub Actions and ArgoCD

## 🎯 What Gets Deployed

### Infrastructure
- **AKS Cluster**: Kubernetes 1.34 with 2 nodes (scalable)
- **Networking**: VNet with dedicated subnet
- **Storage**: Azure-managed persistent volumes

### GitOps & Automation
- **ArgoCD**: Automated application deployment with app-of-apps pattern
- **GitHub Actions**: Dual-credential CI/CD pipeline
- **Terraform**: Infrastructure as Code with remote state

### Applications & Services
- **nginx**: Web server with KEDA autoscaling
- **KEDA**: Event-driven autoscaling (CPU/Memory triggers)
- **Prometheus Stack**: Metrics collection and alerting
- **Grafana**: Metrics visualization and dashboards
- **Loki**: Log aggregation backend
- **Promtail**: Log collection from all pods

## 🔐 Security Features

- ✅ **Azure Workload Identity (OIDC)**: No stored credentials
- ✅ **Federated Authentication**: GitHub Actions authenticates via OIDC
- ✅ **Dual-Credential Approach**: Separate read/write permissions
- ✅ **Azure RBAC**: Role-based access control on AKS
- ✅ **Encrypted State**: Terraform state in Azure Storage with encryption
- ✅ **Least Privilege**: Minimal permissions for each service principal
- ✅ **No Secrets in Code**: All sensitive data in GitHub Secrets

## 📋 Prerequisites

- Azure CLI (`az login`)
- GitHub CLI (`gh auth login`)
- Terraform (v1.13.5+)
- kubectl
- Git

## 🚀 Quick Start (3 Steps)

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
1. Run terraform plan (security scan)
2. Deploy AKS cluster (~15 minutes)
3. Install ArgoCD
4. Deploy all applications automatically

## 🏗️ Architecture

### Dual-Credential CI/CD

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Pull Request (Feature Branch)                             │
│  ├─ Service Principal: aks-gitops-lab-readonly            │
│  ├─ Permissions: Reader, Storage access, AKS read         │
│  ├─ Action: terraform plan only                           │
│  └─ Purpose: Safe testing before merge                    │
│                                                             │
│  Main Branch (After Merge)                                 │
│  ├─ Service Principal: aks-gitops-lab-github              │
│  ├─ Permissions: Contributor, User Access Admin           │
│  ├─ Action: terraform apply                               │
│  └─ Purpose: Deploy infrastructure                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### GitOps Flow

```
Developer → PR → Plan (read-only) → Review → Merge → Apply (full-access) → ArgoCD syncs apps
```

### Application Deployment

```
┌──────────────────────────────────────────────────────────────┐
│                        ArgoCD                                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  core-apps (App of Apps)                                    │
│  ├─ Monitors: argocd-apps/ directory                       │
│  ├─ Auto-sync: Every 30 seconds                            │
│  └─ Auto-prune: Removes deleted apps                       │
│                                                              │
│  Applications                                                │
│  ├─ nginx (with KEDA autoscaling)                          │
│  ├─ keda (autoscaling controller)                          │
│  ├─ kube-prometheus-stack (monitoring)                     │
│  ├─ loki (log aggregation)                                 │
│  └─ promtail (log collection)                              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
.
├── .github/workflows/
│   ├── terraform.yml      # Main CI/CD pipeline
│   └── destroy.yml        # Infrastructure cleanup
├── apps/                  # Helm charts for applications
│   ├── nginx/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── namespace.yaml
│   │       └── scaledobject.yaml  # KEDA autoscaling
│   ├── keda/
│   ├── kube-prometheus-stack/
│   ├── loki/
│   └── promtail/
├── argocd-apps/          # ArgoCD application definitions
│   ├── nginx.yaml
│   ├── keda.yaml
│   ├── kube-prometheus-stack.yaml
│   ├── loki.yaml
│   └── promtail.yaml
├── modules/              # Terraform modules
│   ├── aks/             # AKS cluster configuration
│   ├── argocd/          # ArgoCD Helm deployment
│   ├── resource-group/  # Azure resource group
│   └── vnet/            # Virtual network
├── scripts/              # Automation scripts
│   ├── bootstrap-backend.sh
│   ├── setup-complete-access.sh
│   └── cleanup-all.sh
├── backend.tf           # Terraform backend configuration
├── main.tf              # Main Terraform configuration
└── README.md
```

## 🔧 Adding Applications

### 1. Create Helm Chart

```bash
mkdir -p apps/myapp/templates
```

Create `apps/myapp/Chart.yaml`:
```yaml
apiVersion: v2
name: myapp
version: 1.0.0
```

Create `apps/myapp/values.yaml`:
```yaml
replicaCount: 2
image:
  repository: myapp
  tag: "latest"
```

### 2. Create ArgoCD Application

Create `argocd-apps/myapp.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: apps/myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 3. Deploy

```bash
git add apps/ argocd-apps/
git commit -m "Add myapp"
git push
```

ArgoCD will automatically deploy your app in ~30 seconds!

## 🎮 Accessing Services

### AKS Cluster

```bash
# Get credentials
az aks get-credentials --resource-group aks-gitops-lab --name aks-gitops-lab-aks --admin

# Check cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

### ArgoCD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

# Open browser
open https://localhost:8080
# Username: admin
# Password: (from above command)
```

### Grafana

```bash
# Port forward
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

# Get password
kubectl get secret kube-prometheus-stack-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Open browser
open http://localhost:3000
# Username: admin
# Password: (from above command)
```

### Prometheus

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
open http://localhost:9090
```

## 🧹 Cleanup

### Complete Cleanup

```bash
./scripts/cleanup-all.sh
```

This removes:
- ✅ Service principals and role assignments
- ✅ GitHub secrets
- ✅ Backend storage account
- ✅ All resource groups
- ✅ Local Terraform state files

### Partial Cleanup (Keep Backend)

```bash
# Destroy infrastructure only
gh workflow run destroy.yml -f confirm=destroy
```

## 🐛 Troubleshooting

### Issue: PR workflow fails with permission error

**Solution:** The readonly service principal needs AKS Cluster Admin role. This is automatically configured in Terraform (`modules/aks/main.tf`).

### Issue: ArgoCD not syncing apps

**Possible causes:**
1. GitHub token expired
2. Repository URL incorrect
3. Branch name mismatch

**Solution:**
```bash
# Check ArgoCD repo secret
kubectl get secret argocd-repo -n argocd -o yaml

# Update if needed
kubectl delete secret argocd-repo -n argocd
# Re-run terraform apply to recreate
```

### Issue: Pods pending due to insufficient resources

**Solution:** Scale up nodes
```bash
# Edit modules/aks/variables.tf
node_count = 3  # Increase from 2

# Commit and push
git add modules/aks/variables.tf
git commit -m "Scale to 3 nodes"
git push
```

### Issue: KEDA ScaledObject shows OutOfSync

**Solution:** This is cosmetic if using ServerSideApply with webhooks. The application is still functional. Remove ServerSideApply if it bothers you:

```yaml
syncOptions:
  - CreateNamespace=true
  # Remove: - ServerSideApply=true
```

## 📊 Monitoring & Observability

### Metrics (Prometheus + Grafana)

- **Node metrics**: CPU, memory, disk, network
- **Pod metrics**: Resource usage per pod
- **Cluster metrics**: Overall cluster health
- **Custom metrics**: Application-specific metrics

### Logs (Loki + Promtail)

- **Centralized logging**: All pod logs in one place
- **Query language**: LogQL for powerful log queries
- **Retention**: Configurable log retention policies
- **Integration**: Grafana dashboards for log visualization

### Autoscaling (KEDA)

- **CPU-based**: Scale on CPU utilization
- **Memory-based**: Scale on memory usage
- **Custom metrics**: Scale on any Prometheus metric
- **Event-driven**: Scale on queue depth, HTTP requests, etc.

## 💰 Cost Optimization

### Current Setup (2 nodes)

- **AKS**: 2 x Standard_B2s nodes (~$60/month)
- **Storage**: Standard_LRS (~$0.10/month)
- **Load Balancer**: Standard (~$20/month)
- **Total**: ~$80-90/month

### Cost Saving Tips

1. **Use spot instances** for non-production workloads
2. **Scale down** when not in use
3. **Use smaller node sizes** for dev/test
4. **Enable cluster autoscaler** to scale to zero
5. **Destroy infrastructure** when not needed

```bash
# Destroy when not in use
gh workflow run destroy.yml -f confirm=destroy

# Redeploy when needed
git commit --allow-empty -m "Redeploy" && git push
```

## 🔒 Security Best Practices

### Implemented

- ✅ No credentials in code or version control
- ✅ Federated authentication (OIDC)
- ✅ Separate read/write service principals
- ✅ Encrypted Terraform state
- ✅ Azure RBAC on AKS cluster
- ✅ Network policies (via Azure CNI)
- ✅ Secrets stored in GitHub Secrets

### Recommended Additions

- 🔲 Azure Key Vault for application secrets
- 🔲 Pod Security Standards enforcement
- 🔲 Network policies for pod-to-pod traffic
- 🔲 Azure Policy for compliance
- 🔲 Azure Defender for Kubernetes
- 🔲 Regular security scanning (Trivy, Snyk)

## 📚 What's Automated

- ✅ Backend storage creation
- ✅ Service principal creation and configuration
- ✅ Role assignments (subscription and cluster level)
- ✅ GitHub secrets (5 of 7 automated)
- ✅ AKS cluster deployment
- ✅ ArgoCD installation and configuration
- ✅ Application deployment via GitOps
- ✅ KEDA autoscaling setup
- ✅ Monitoring stack deployment

## ✋ What's Manual

- ❌ Update `backend.tf` with storage account name (one-time)
- ❌ Add `GIT_USERNAME` secret (one-time)
- ❌ Add `GIT_TOKEN` secret (one-time)

## 🎓 Learning Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/azure/aks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [KEDA Documentation](https://keda.sh/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitOps Principles](https://opengitops.dev/)

## 📝 License

MIT

## 🤝 Contributing

This is a learning lab project. Feel free to fork and adapt for your needs!

## ⚠️ Important Notes

- **Not for production**: This is a learning environment
- **Costs money**: Remember to destroy resources when done
- **Security**: Review and adapt security settings for your use case
- **Monitoring**: Adjust resource limits based on your workload
