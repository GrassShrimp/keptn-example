resource "helm_release" "prometheus" {
  name              = "prometheus"
  repository        = "https://prometheus-community.github.io/helm-charts" 
  chart             = "prometheus"
  version           = var.PROMETHEUS_VERSION
  namespace         = "monitoring"
  values = [
  <<EOF
  alertmanager:
    baseURL: http://alertmanager.${module.kind-istio-metallb.ingress_ip_address}.nip.io
    persistentVolume:
      storageClass: standard
  server:
    persistentVolume:
      storageClass: standard
  EOF
  ]
  create_namespace  = true
  depends_on = [
    module.kind-istio-metallb
  ]
}
resource "local_file" "monitoring-ingress" {
  content  = <<-EOF
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: monitoring
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - "*.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: prometheus
  spec:
    hosts:
    - "prometheus.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
    gateways:
    - monitoring
    http:
    - route:
      - destination:
          port:
            number: 80
          host: prometheus-server.${helm_release.prometheus.namespace}.svc.cluster.local
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: alertmanager
  spec:
    hosts:
    - "alertmanager.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
    gateways:
    - monitoring
    http:
    - route:
      - destination:
          port:
            number: 80
          host: prometheus-alertmanager.${helm_release.prometheus.namespace}.svc.cluster.local
  EOF
  filename = "${path.root}/configs/monitoring-ingress.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${helm_release.prometheus.namespace}"
  }
}
resource "null_resource" "keptn-prometheus" {
  provisioner "local-exec" {
    command = "kubectl apply -f  https://raw.githubusercontent.com/keptn-contrib/prometheus-service/release-0.6.1/deploy/service.yaml"
  }
  provisioner "local-exec" {
    # Prometheus installed namespace
    command = "kubectl set env deployment/prometheus-service -n ${helm_release.keptn.namespace} --containers=\"prometheus-service\" PROMETHEUS_NS=\"${helm_release.prometheus.namespace}\""
  }
  provisioner "local-exec" {
    # Setup Prometheus Endpoint
    command = "kubectl set env deployment/prometheus-service -n ${helm_release.keptn.namespace} --containers=\"prometheus-service\" PROMETHEUS_ENDPOINT=\"http://prometheus-server.${helm_release.prometheus.namespace}.svc.cluster.local:80\""
  }
  provisioner "local-exec" {
    # Alert Manager installed namespace
    command = "kubectl set env deployment/prometheus-service -n ${helm_release.keptn.namespace} --containers=\"prometheus-service\" ALERT_MANAGER_NS=\"${helm_release.prometheus.namespace}\""
  }
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/keptn-contrib/prometheus-service/release-0.6.1/deploy/role.yaml -n ${helm_release.prometheus.namespace}"
  }
}