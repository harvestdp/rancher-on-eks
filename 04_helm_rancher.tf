# install rancher
resource "helm_release" "rancher" {
  depends_on       = [time_sleep.wait_for_ingress_nginx]
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  version          = var.rancher_version
  namespace        = "cattle-system"
  create_namespace = true

  set {
    name  = "helmVersion"
    value = "v3"
  }
  set {
    name  = "hostname"
    value = local.full_domain
  }

  set {
    name  = "ingress.tls.source"
    value = "letsEncrypt"
  }

  set {
    name  = "letsEncrypt.email"
    value = var.cert_manager_letsencrypt_email
  }

  set {
    name  = "letsEncrypt.environment"
    value = var.cert_manager_letsencrypt_environment
  }

}

resource "null_resource" "wait_for_rancher" {
  depends_on = [helm_release.rancher]
  provisioner "local-exec" {
    command     = <<EOF
while [ "$${subject}" != "*  subject: CN=$${RANCHER_HOSTNAME}" ]; do
    subject=$(curl -vk -m 2 "https://$${RANCHER_HOSTNAME}/ping" 2>&1 | grep "subject:")
    echo "Cert Subject Response: $${subject}"
    if [ "$${subject}" != "*  subject: CN=$${RANCHER_HOSTNAME}" ]; then
      sleep 10
    fi
done
while [ "$${resp}" != "pong" ]; do
    resp=$(curl -sSk -m 2 "https://$${RANCHER_HOSTNAME}/ping")
    echo "Rancher Response: $${resp}"
    if [ "$${resp}" != "pong" ]; then
      sleep 10
    fi
done
EOF
    interpreter = ["bash", "-c"]

    environment = {
      RANCHER_HOSTNAME = local.full_domain
    }
  }
}
