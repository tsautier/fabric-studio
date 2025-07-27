#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-echoserver-ingress-traefik.sh
# DESCRIPTION:    Deploy the echoserver app in namespace echoserver
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-30
# VERSION:        1.1
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
# 2025-07-06 sdubois Added ForiADC Ingress
# 2025-07-23 sdubois Moved ForiADC Ingress in seperate script
#===============================================================================

getObject() {
  local NAMESPACE="$1"
  local OBJ="$2"
  local KEY="$3"
  kubectl -n $NAMESPACE get $OBJ -o jsonpath="{.items[?(@.metadata.name==\"$KEY\")].metadata.name}" | grep -q "$KEY"
}

NAMESPACE=ecs-ingress-traefik
APPNAME=echoserver
APPDESC="Echoserver Demo"
DOCKER_IMAGE=k8s.gcr.io/echoserver:1.10
CONTAINER_PORT=8080
EXPOSE_PORT=80
EXPOSE_PORT_ADC=1040
SERVICE_TYPE=ClusterIP
TLS_FORTIDEMO_CA_CERT=ca.crt
TLS_FORTIDEMO_CERTPATH=$HOME/cert/fortidemo

# Traefic Ingress Condfiguraiton
TLS_INGRESS_APPINT_CERTNAME=k3s-apps-internal
TLS_INGRESS_APPINT_SECRET=fortidemo-appint-tls-cert
TLS_INGRESS_APPINT_EXPRIRE=$(openssl x509 -in $TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPINT_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')
TLS_INGRESS_APPINT_DOMAIN=apps-int.fortidemo.net
TLS_INGRESS_APPINT_IPADDR=$(dig +short $APPNAME.$TLS_INGRESS_APPINT_DOMAIN)

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $HOME/workspace/tanzu-demo-hub/functions ] && . $HOME/workspace/tanzu-demo-hub/functions

if [ "$1" == "delete" ]; then
  echo "=> Undeploy '$APPDESC' Deployment ($APPNAME)"
  getObject $NAMESPACE ingress ${APPNAME}-fortidemo && kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo
  getObject $NAMESPACE svc ${APPNAME} && kubectl -n $NAMESPACE delete svc ${APPNAME}
  getObject $NAMESPACE deployment $APPNAME && kubectl -n $NAMESPACE delete deployment $APPNAME
  getObject $NAMESPACE secret $TLS_INGRESS_APPINT_SECRET && kubectl -n $NAMESPACE delete secret $TLS_INGRESS_APPINT_SECRET
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

echo "   ▪ Expose Container Port: $CONTAINER_PORT to $EXPOSE_PORT service Type: $SERVICE_TYPE"
getObject $NAMESPACE svc $APPNAME || cat <<EOF | kubectl -n $NAMESPACE apply -f -
apiVersion: v1
kind: Service
metadata:
  name: $APPNAME
spec:
  selector:
    app: $APPNAME
  ports:
    - protocol: TCP
      port: $EXPOSE_PORT
      targetPort: $CONTAINER_PORT
  type: $SERVICE_TYPE
EOF

echo "   ▪ Create TLS Certificate secret ($TLS_INGRESS_APPINT_SECRET) Expiring: $TLS_INGRESS_APPINT_EXPRIRE"
getObject $NAMESPACE secret $TLS_INGRESS_APPINT_SECRET || kubectl create secret tls $TLS_INGRESS_APPINT_SECRET \
  --namespace $NAMESPACE \
  --cert="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPINT_CERTNAME}.crt" \
  --key="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPINT_CERTNAME}.key"

echo "   ▪ Create Ingress Resource for $APPNAME for Domain: $TLS_INGRESS_APPINT_DOMAIN"
getObject $NAMESPACE ingress ${APPNAME}-fortidemo  || cat <<EOF | kubectl -n $NAMESPACE apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APPNAME}-fortidemo
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure      # Use only HTTPS entrypoint
    traefik.ingress.kubernetes.io/router.tls: "true"                 # Enable TLS
spec:
  ingressClassName: traefik
  tls:
  - secretName: $TLS_INGRESS_APPINT_SECRET   # Secret containing the TLS certificate
    hosts:
    - "*.$TLS_INGRESS_APPINT_DOMAIN"     # Wildcard domain covered by the certificate
  rules:
  - host: ${APPNAME}.$TLS_INGRESS_APPINT_DOMAIN   # Your specific hostname
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
echo "   => curl https://$APPNAME.$TLS_INGRESS_APPINT_DOMAIN --cacert $TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT"
echo ""

