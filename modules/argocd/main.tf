resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "oci://ghcr.io/argoproj/argo-helm"
  chart      = "argo-cd"
  namespace  = var.namespace
  version    = var.argocd_version

  create_namespace = true
  timeout          = 600

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "configs.cm.timeout\\.reconciliation"
    value = "30s"
  }
}

resource "helm_release" "argocd_apps" {
  count = var.git_repo_url != "" ? 1 : 0

  name       = "argocd-apps"
  repository = "oci://ghcr.io/argoproj/argo-helm"
  chart      = "argocd-apps"
  namespace  = var.namespace

  timeout = 600

  values = [
    yamlencode({
      applications = {
        app-of-apps = {
          namespace  = var.namespace
          finalizers = ["resources-finalizer.argocd.argoproj.io"]
          project    = "default"
          source = {
            repoURL        = var.git_repo_url
            targetRevision = var.git_target_revision
            path           = var.git_apps_path
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = var.namespace
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret" "argocd_repo" {
  count = var.github_token != "" ? 1 : 0

  metadata {
    name      = "${var.namespace}-repo"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.git_repo_url
    username = var.github_username
    password = var.github_token
  }

  depends_on = [helm_release.argocd]
}