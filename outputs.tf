output "cluster_name" {
  description = "Cluster name."
  value       = local.cluster_name
}

output "rancher_admin_domain" {
  description = "Domain of Rancher instance."
  value       = local.full_domain
}

output "rancher_admin_url" {
  description = "Rancher admin user url."
  value       = "https://${local.full_domain}"
}

output "rancher_admin_token" {
  value       = rancher2_bootstrap.admin.token
  description = "Rancher admin user token."
  sensitive   = true
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "kubeconfig_filename" {
  description = "The filename of the generated kubectl config."
  value       = module.eks.kubeconfig_filename
}
