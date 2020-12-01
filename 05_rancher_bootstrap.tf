provider "rancher2" {
  alias     = "bootstrap"
  bootstrap = true
  api_url   = "https://${local.full_domain}"
}

# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  depends_on = [helm_release.rancher]
  provider   = rancher2.bootstrap
  password   = var.rancher_admin_password
  telemetry  = true
}

# Provider config for admin
provider "rancher2" {
  alias     = "admin"
  api_url   = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
}

# # Create a new rancher2 Cloud Credential
# resource "aws_iam_user" "cloud_credential" {
#   name = local.cluster_name
# }
# resource "aws_iam_access_key" "cloud_credential" {
#   user = aws_iam_user.cloud_credential.name
# }
# resource "aws_iam_user_policy_attachment" "cloud_credential" {
#   user       = aws_iam_user.cloud_credential.name
#   policy_arn = var.cloud_credential_policy_arn
# }
# resource "rancher2_cloud_credential" "cloud_credential" {
#   provider    = rancher2.admin
#   name        = local.cluster_name
#   description = "For this Rancher cluster only"
#   amazonec2_credential_config {
#     access_key = aws_iam_access_key.cloud_credential.id
#     secret_key = aws_iam_access_key.cloud_credential.secret
#   }
# }
