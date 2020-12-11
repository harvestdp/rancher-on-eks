resource "random_string" "suffix" {
  count   = var.cluster_name == "" ? 1 : 0
  length  = 8
  special = false
  lower   = true
  upper   = false
}

locals {
  cluster_name = var.cluster_name == "" ? "rancher-${random_string.suffix[0].result}" : var.cluster_name
  name         = local.cluster_name
  subdomain    = local.cluster_name
  full_domain  = "${local.subdomain}.${var.base_domain}"
}
