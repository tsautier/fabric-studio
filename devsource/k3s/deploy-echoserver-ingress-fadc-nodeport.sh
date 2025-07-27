#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-echoserver-ingress-fadc-nodeport.sh
# DESCRIPTION:    Deploy the echoserver app in namespace echoserver
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-30
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
# 2025-07-06 sdubois Added ForiADC Ingress
#===============================================================================

getObject() {
  local NAMESPACE="$1"
  local OBJ="$2"
  local KEY="$3"
  kubectl -n $NAMESPACE get $OBJ -o jsonpath="{.items[?(@.metadata.name==\"$KEY\")].metadata.name}" | grep -q "$KEY"
}

NAMESPACE=ecs-ingress-fadc
APPNAME=echoserver
APPDESC="Echoserver Demo"
DOCKER_IMAGE=k8s.gcr.io/echoserver:1.10
CONTAINER_PORT=8080
EXPOSE_PORT=80
SERVICE_TYPE=ClusterIP
TLS_FORTIDEMO_CA_CERT=ca.crt
TLS_FORTIDEMO_CERTPATH=$HOME/cert/fortidemo

# FortiADC Ingress Configuration
TLS_INGRESS_APPADC_CERTNAME=k3s-apps-adc-echoserver
TLS_INGRESS_APPADC_SECRET=fortidemo-appadc-tls-cert
TLS_INGRESS_APPADC_EXPRIRE=$(openssl x509 -in $TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')
TLS_INGRESS_APPADC_DOMAIN=apps-adc.fortidemo.net
TLS_INGRESS_APPADC_IPADDR=$(dig +short $APPNAME.$TLS_INGRESS_APPADC_DOMAIN)

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $HOME/workspace/tanzu-demo-hub/functions ] && . $HOME/workspace/tanzu-demo-hub/functions

if [ "$1" == "delete" ]; then
  echo "=> Undeploy '$APPDESC' Deployment ($APPNAME)"
  getObject $NAMESPACE ingress ${APPNAME}-fortidemo && kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo
  getObject $NAMESPACE svc $APPNAME && kubectl -n $NAMESPACE delete svc $APPNAME
  getObject $NAMESPACE secret $TLS_INGRESS_APPADC_SECRET && kubectl -n $NAMESPACE delete secret $TLS_INGRESS_APPADC_SECRET

  getObject $NAMESPACE deployment $APPNAME && kubectl -n $NAMESPACE delete deployment $APPNAME
  getObject $NAMESPACE namespace $NAMESPACE && kubectl delete ns $NAMESPACE

  echo "$APPDESC undeployed successfully"

  exit
fi

echo "=> Deploy '$APPDESC' Deployment ($APPNAME)"
echo "   ▪ Create / update namespace $NAMESPACE"
getObject $NAMESPACE namespace $NAMESPACE || kubectl create ns $NAMESPACE > /dev/null 2>&1

echo "   ▪ Create a docker pull secret"
dockerPullSecret $NAMESPACE > /dev/null 2>&1

echo "   ▪ Create Deployment"
getObject $NAMESPACE deployment $APPNAME || cat <<EOF | kubectl -n $NAMESPACE  apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APPNAME
  labels:
    app: $APPNAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APPNAME
  template:
    metadata:
      labels:
        app: $APPNAME
    spec:
      containers:
      - name: $APPNAME
        image: $DOCKER_IMAGE
        ports:
        - containerPort: $CONTAINER_PORT
        resources:
          limits:
            memory: "4Gi"
            cpu: "1"
          requests:
            memory: "1Gi"
            cpu: "300m"
EOF

echo "   ▪ Create Secret with FortiADC Access Parameters"
getObject $NAMESPACE secret $FortiADC || kubectl create secret generic fad-login -n $NAMESPACE \
  --from-literal=username=admin --from-literal=password='F0rt!net' > /dev/null 2>&1

echo "   ▪ Create TLS Certificate secret ($TLS_INGRESS_APPADC_SECRET) Expiring: $TLS_INGRESS_APPADC_EXPRIRE"
getObject $NAMESPACE secret $TLS_INGRESS_APPADC_SECRET || kubectl create secret tls $TLS_INGRESS_APPADC_SECRET \
  --namespace $NAMESPACE \
  --cert="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt" \
  --key="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.key"

echo "   ▪ Expose Container Port: $CONTAINER_PORT to $EXPOSE_PORT service Type: NodePort"
getObject $NAMESPACE svc $APPNAME && kubectl -n $NAMESPACE delete svc $APPNAME
cat <<EOF | kubectl -n $NAMESPACE apply -f -
kind: Service
apiVersion: v1
metadata:
  name: $APPNAME
  namespace: $NAMESPACE
  annotations: {
    "health-check-ctrl" : "enable",
    "health-check-relation" : "OR",
    "health-check-list" : "LB_HLTHCK_ICMP",
    "real-server-ssl-profile" : "NONE"
  }
spec:
  type: NodePort
  ports:
  - protocol: TCP
    port: $EXPOSE_PORT
    targetPort: $CONTAINER_PORT
  selector:
    app: $APPNAME
  sessionAffinity: None
EOF

  echo "   ▪ Create Ingress Resource for $APPNAME for Domain: $TLS_INGRESS_APPADC_DOMAIN"
  getObject $NAMESPACE ingress ${APPNAME}-fortidemo && kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo
  cat <<EOF | kubectl -n $NAMESPACE apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APPNAME}-fortidemo
  annotations: {
    "virtual-server-ip" : "$TLS_INGRESS_APPADC_IPADDR",
    "virtual-server-interface" : "port2",
    "fortiadc-ip" : "10.1.1.3",
    "fortiadc-login" : "fad-login",
    "fortiadc-vdom" : "root",
    "fortiadc-ctrl-log" : "enable",
    "virtual-server-port" : "443",
    "load-balance-method" : "LB_METHOD_LEAST_CONNECTION",
    "load-balance-profile" : "LB_PROF_HTTPS"
  }
spec:
  ingressClassName:  fadc-ingress-controller
  tls:
  - secretName: $TLS_INGRESS_APPADC_SECRET   # Secret containing the TLS certificate
    hosts:
    - "$APPNAME.$TLS_INGRESS_APPADC_DOMAIN"     # Wildcard domain covered by the certificate
  rules:
  - host: ${APPNAME}.$TLS_INGRESS_APPADC_DOMAIN   # Your specific hostname
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $APPNAME
            port:
              number: $EXPOSE_PORT
EOF

kubectl -n $NAMESPACE wait --for=condition=Ready pod -l app=$APPNAME --timeout=300s

echo "   ▪ Show Deployment"
echo "----------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE get all,ingress,Middleware
echo "----------------------------------------------------------------------------------------------------------------"
echo "kubectl -n $NAMESPACE get all,ingress,Middleware"
echo 

echo "   ▪ Test Application for Domain: $TLS_INGRESS_APPINT_DOMAIN and $TLS_INGRESS_APPADC_DOMAIN"
echo "   => curl https://$APPNAME.$TLS_INGRESS_APPADC_DOMAIN --cacert $TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT"
echo ""

