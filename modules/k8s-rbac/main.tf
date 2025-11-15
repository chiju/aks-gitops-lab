resource "kubernetes_cluster_role_binding" "github_actions_admin" {
  metadata {
    name = "github-actions-admin"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  
  subject {
    kind      = "User"
    name      = var.service_principal_object_id
    api_group = "rbac.authorization.k8s.io"
  }
}
