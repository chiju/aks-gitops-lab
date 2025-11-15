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
    name      = "d05a88f1-a501-427a-be8d-39a47ef4b29e"
    api_group = "rbac.authorization.k8s.io"
  }
}
