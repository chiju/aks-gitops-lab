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

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "d2c2211d-193c-47e7-8247-85465d5ff1a6"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS cluster admins"
  type        = list(string)
  default     = []
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