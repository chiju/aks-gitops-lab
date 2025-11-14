variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
}

variable "service_type" {
  description = "Kubernetes service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"
}