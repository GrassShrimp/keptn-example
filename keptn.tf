resource "kubernetes_namespace" "keptn" {
  metadata {
    name = "keptn"
    labels = {
      "keptn.sh/managed-by" = "keptn"
    }
    annotations = {
      "keptn.sh/managed-by" = "keptn"
    }
  }
}
resource "helm_release" "keptn" {
  name            = "keptn"
  repository      = "https://storage.googleapis.com/keptn-installer"
  chart           = "keptn"
  version         = var.KEPTN_VERSION
  namespace       = kubernetes_namespace.keptn.metadata[0].name
  cleanup_on_fail = true
  values = [
    <<-EOF
  continuous-delivery:
    enabled: true
  control-plane:
    configurationService:
      storageClass: standard
    bridge:
      secret:
        enabled: false
    mongodb:
      enabled: true
  EOF
  ]
  depends_on = [
    module.kind-istio-metallb
  ]
}
resource "local_file" "keptn-ingress" {
  content  = <<-EOF
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: keptn
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - "keptn.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: keptn
  spec:
    hosts:
    - "keptn.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
    gateways:
    - keptn
    http:
    - route:
      - destination:
          port:
            number: 80
          host: api-gateway-nginx.keptn.svc.cluster.local
  EOF
  filename = "${path.root}/configs/keptn-ingress.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${helm_release.keptn.namespace}"
  }
  depends_on = [
    helm_release.keptn
  ]
}
resource "helm_release" "jmeter-service" {
  name            = "jmeter-service"
  repository      = "https://storage.googleapis.com/keptn-installer"
  chart           = "jmeter-service"
  version         = var.KEPTN_VERSION
  namespace       = kubernetes_namespace.keptn.metadata[0].name
  cleanup_on_fail = true
  depends_on = [
    helm_release.keptn
  ]
}
resource "helm_release" "helm-service" {
  name            = "helm-service"
  repository      = "https://storage.googleapis.com/keptn-installer"
  chart           = "helm-service"
  version         = var.KEPTN_VERSION
  namespace       = kubernetes_namespace.keptn.metadata[0].name
  cleanup_on_fail = true
  depends_on = [
    helm_release.keptn
  ]
}