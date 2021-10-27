output "keptn-auth" {
  value = "keptn auth --endpoint=http://keptn.${module.kind-istio-metallb.ingress_ip_address}.nip.io/api --api-token=$(kubectl get secret keptn-api-token -n keptn -o jsonpath={.data.keptn-api-token} | base64 --decode)"
}