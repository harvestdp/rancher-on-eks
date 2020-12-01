# install ingress-nginx
resource "helm_release" "ingress_nginx" {
  depends_on       = [helm_release.cert_manager]
  version          = var.ingress_nginx_version
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  values = [
    file("helm-values/ingress-nginx-values.yaml")
  ]
}

data "kubernetes_service" "ingress_nginx_service" {
  depends_on = [helm_release.ingress_nginx]
  metadata {
    name      = "${helm_release.ingress_nginx.name}-controller"
    namespace = helm_release.ingress_nginx.namespace
  }
}

data "aws_route53_zone" "dns_zone" {
  name = var.base_domain
}

resource "aws_route53_record" "rancher_cluster_ingress" {
  depends_on = [data.kubernetes_service.ingress_nginx_service]
  zone_id    = data.aws_route53_zone.dns_zone.zone_id
  name       = local.full_domain
  type       = "CNAME"
  records    = [data.kubernetes_service.ingress_nginx_service.load_balancer_ingress.0.hostname]
  ttl        = 300
}

##
## Added a delay after ingress route53 to ensure
## rancher helm installs correctly.
resource "time_sleep" "wait_for_ingress_nginx" {
  depends_on      = [aws_route53_record.rancher_cluster_ingress]
  create_duration = "60s"
}
