variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-gitops-lab"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "github_username" {
  description = "GitHub username for ArgoCD repository access"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub token for ArgoCD repository access"
  type        = string
  default     = ""
  sensitive   = true
}