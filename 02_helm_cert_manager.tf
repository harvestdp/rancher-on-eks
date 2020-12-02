resource "kubernetes_namespace" "cert_manager" {
  depends_on = [module.eks]
  metadata {
    name = "cert-manager"
    labels = {
      "certmanager.k8s.io/disable-validation" = "true"
    }
  }
  # This destory provisioner is needed since Rancher adds "finalizers" to this namespace, which 
  # upsets the terraform removal process since Rancher has already been removed.
  provisioner "local-exec" {
    when        = destroy
    command     = "KUBECONFIG=$(find . -type f -name 'kubeconfig_*' | head -n1) kubectl patch ns cert-manager -p '{\"metadata\":{\"finalizers\":null}}'"
    interpreter = ["bash", "-c"]
  }
  # We need to ignore annotations and labels since Rancher patches this namespace, which 
  # confuses terraform.
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

# --- CRD installation -- All this is required ---
resource "kubernetes_cluster_role" "prepare_cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]
  metadata {
    name = "prepare-cert-manager"
    labels = {
      app = "prepare-cert-manager"
    }
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["create", "get", "patch", "delete"]
  }
}

resource "kubernetes_service_account" "prepare_cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]
  metadata {
    name      = "prepare-cert-manager"
    namespace = "cert-manager"
    labels = {
      app = "prepare-cert-manager"
    }
  }
}

resource "kubernetes_cluster_role_binding" "prepare_cert_manager" {
  depends_on = [
    kubernetes_service_account.prepare_cert_manager,
    kubernetes_cluster_role.prepare_cert_manager
  ]
  metadata {
    name = "prepare-cert-manager"
    labels = {
      app = "prepare-cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "prepare-cert-manager"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "prepare-cert-manager"
    namespace = "cert-manager"
  }
}

resource "kubernetes_job" "prepare_cert_manager" {
  depends_on = [kubernetes_cluster_role_binding.prepare_cert_manager]
  metadata {
    name      = "prepare-cert-manager-${replace(var.cert_manager_version, "/[^v0-9]/", "-")}"
    namespace = "cert-manager"
  }
  spec {
    template {
      metadata {}
      spec {
        service_account_name            = "prepare-cert-manager"
        automount_service_account_token = true
        container {
          name  = "kubectl"
          image = "bitnami/kubectl"
          command = [
            "bash",
            "-c",
            join(" ", [
              "kubectl",
              "apply",
              "-f",
              "https://github.com/jetstack/cert-manager/releases/download/${var.cert_manager_version}/cert-manager.crds.yaml",
              "||",
              "sleep 3600"
            ])
          ]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
}
# --- END CRD installation ---

# install cert-manager
resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_job.prepare_cert_manager]
  version    = var.cert_manager_version
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  values     = var.cert_manager_values_filename != "" ? [file(var.cert_manager_values_filename)] : []
}
