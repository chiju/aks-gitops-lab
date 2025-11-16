variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
}

variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
}

variable "git_target_revision" {
  description = "Git branch or tag to track"
  type        = string
  default     = "main"
}

variable "git_apps_path" {
  description = "Path in git repository containing ArgoCD application manifests"
  type        = string
  default     = "argocd-apps"
}

variable "github_username" {
  description = "GitHub username for repository access (optional for public repos)"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub token for repository access (optional for public repos)"
  type        = string
  default     = ""
  sensitive   = true
}