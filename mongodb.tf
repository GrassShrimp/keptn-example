resource "null_resource" "download_mongodb-kubernetes-operator" {
  provisioner "local-exec" {
    command = "git clone https://github.com/mongodb/mongodb-kubernetes-operator.git"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -r ${path.root}/mongodb-kubernetes-operator"
  }
  depends_on = [
    null_resource.installing-istio
  ]
}
resource "helm_release" "mongodb-operator" {
  name             = "mongodb-operator"
  repository       = "${path.root}/mongodb-kubernetes-operator"
  chart            = "helm-chart"
  version          = "0.7.0"
  namespace        = "mongodb"
  create_namespace = true
  cleanup_on_fail  = true
  depends_on = [
    null_resource.download_mongodb-kubernetes-operator
  ]
}
resource "local_file" "mongodb_template" {
  content  = <<-EOF
  ---
  apiVersion: mongodbcommunity.mongodb.com/v1
  kind: MongoDBCommunity
  metadata:
    name: mongodb
  spec:
    members: 1
    type: ReplicaSet
    version: "4.4.0"
    security:
      authentication:
        modes: ["SCRAM"]
      tls:
        enabled: false
    users:
    - name: admin
      db: admin
      passwordSecretRef:
        name: mongo-admin-password
      roles:
      - name: clusterAdmin
        db: admin
      - name: userAdminAnyDatabase
        db: admin
      scramCredentialsSecretName: admin-scram
    statefulSet:
      spec:
        template:
          spec:
            containers:
            - name: mongodb-agent
              readinessProbe:
                failureThreshold: 50
                initialDelaySeconds: 10
              resources:
              limits:
                cpu: "0.2"
                memory: 250M
              requests:
                cpu: "0.2"
                memory: 200M
            - name: mongod
              resources:
                limits:
                  cpu: "0.2"
                  memory: 250M
                requests:
                  cpu: "0.2"
                  memory: 200M
    additionalMongodConfig:
      storage.wiredTiger.engineConfig.journalCompressor: zlib
  ---
  apiVersion: v1
  kind: Secret
  metadata:
    name: mongo-admin-password
  type: Opaque
  stringData:
    password: admin
  EOF
  filename = "${path.root}/configs/mongodb_template.yaml"
  depends_on = [
    helm_release.mongodb-operator
  ]
}
resource "null_resource" "install-mongodb" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.mongodb_template.filename} -n ${helm_release.mongodb-operator.namespace}"
  }
  depends_on = [
    local_file.mongodb_template
  ]
}
resource "local_file" "mongo-ingress" {
  content = <<-EOF
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: mongo
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 27017
        name: mongo
        protocol: MONGO
      hosts:
      - "mongo-0.pinjyun.work"
      - "mongo-1.pinjyun.work"
      - "mongo-2.pinjyun.work"
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: mongo-0
  spec:
    hosts:
    - "mongo-0.pinjyun.work"
    gateways:
    - mongo
    tcp:
    - match:
      - port: 27017
      route:
      - destination:
          host: mongodb-0.mongodb-svc.mongodb.svc.cluster.local
          port:
            number: 27017
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: mongo-1
  spec:
    hosts:
    - "mongo-1.pinjyun.work"
    gateways:
    - mongo
    tcp:
    - match:
      - port: 27017
      route:
      - destination:
          host: mongodb-1.mongodb-svc.mongodb.svc.cluster.local
          port:
            number: 27017
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: mongo-2
  spec:
    hosts:
    - "mongo-2.pinjyun.work"
    gateways:
    - mongo
    tcp:
    - match:
      - port: 27017
      route:
      - destination:
          host: mongodb-2.mongodb-svc.mongodb.svc.cluster.local
          port:
            number: 27017
  ---
  EOF
  filename = "${path.root}/configs/mongo-ingress.yaml"
}
resource "null_resource" "installing-mongo-ingress" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.mongo-ingress.filename} -n ${helm_release.mongodb-operator.namespace}"
  }
  depends_on = [
    local_file.mongodb_template
  ]
}
