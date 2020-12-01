resource "random_string" "suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

locals {
  name         = "rancher-${random_string.suffix.result}"
  cluster_name = local.name
  subdomain    = "rancher-${random_string.suffix.result}"
  full_domain  = "${local.subdomain}.${var.base_domain}"
}
