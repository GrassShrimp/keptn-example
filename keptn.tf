resource "helm_release" "keptn" {
  name             = "keptn"
  repository       = "https://storage.googleapis.com/keptn-installer"
  chart            = "keptn"
  version          = "0.9.2"
  namespace        = "keptn"
  create_namespace = true
  cleanup_on_fail  = true
  values = [
  <<-EOF
  continuous-delivery:
    enabled: true
  control-plane:
    configurationService:
      storageClass: standard
    mongodb:
      enabled: false
      host: mongodb-0.mongodb-svc.mongodb.svc.cluster.local
      user: admin
      password: admin
      adminPassword: admin
  EOF
  ]
  depends_on = [
    null_resource.install-mongodb
  ]
}