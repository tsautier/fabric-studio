#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-toolbox-ingress.sh
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

[ "$ADC_INGRESS" == "" ] && ADC_INGRESS=1
NAMESPACE=toolbox-lb
APPNAME=toolbox
APPDESC="ToolsBox Demo"
DOCKER_IMAGE=sadubois/toolbox:1.2.0
CONTAINER_PORT=8080
EXPOSE_PORT=8080
SERVICE_TYPE=LoadBalancer
TLS_FORTIDEMO_CA_CERT=ca.crt
TLS_FORTIDEMO_CERTPATH=$HOME/cert/fortidemo

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $HOME/workspace/tanzu-demo-hub/functions ] && . $HOME/workspace/tanzu-demo-hub/functions

if [ "$1" == "delete" -o "$1" == "delete" ]; then 
  echo "=> Undeploy '$APPDESC' Deployment ($APPNAME)"
  getObject $NAMESPACE svc ${APPNAME} && kubectl -n $NAMESPACE delete svc ${APPNAME}
  getObject $NAMESPACE deployment $APPNAME && kubectl -n $NAMESPACE delete deployment $APPNAME
  getObject $NAMESPACE namespace $NAMESPACE && kubectl delete ns $NAMESPACE
  echo "$APPDESC undeployed successfuully"

  exit
fi

echo "=> Deploy '$APPDESC' Deployment ($APPNAME)"
echo " ▪ Create / update namespace $NAMESPACE"
getObject $NAMESPACE svc ${APPNAME} || kubectl create ns $NAMESPACE > /dev/null 2>&1

echo " ▪ Create a docker pull secret"
dockerPullSecret $NAMESPACE > /dev/null 2>&1

echo " ▪ Create Deployment"
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
        env:
        - name: HTTP_PROXY
          value: "http://proxy.fabric-studio.fortidemo.ch:8080"
        - name: HTTPS_PROXY
          value: "http://proxy.fabric-studio.fortidemo.ch:8080"
        - name: NO_PROXY
          value: "localhost,127.0.0.1,*.svc.cluster.local"
        resources:
          limits:
            memory: "4Gi"
            cpu: "1"
          requests:
            memory: "1Gi"
            cpu: "300m"
EOF

echo " ▪ Expose Container Port: $CONTAINER_PORT to $EXPOSE_PORT service Type: $SERVICE_TYPE"
getObject $NAMESPACE svc ${APPNAME} || cat <<EOF | kubectl -n $NAMESPACE apply -f -
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

echo " ▪ Show Deployment"
echo "----------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE get all,ingress,Middleware,sa,secret
echo "----------------------------------------------------------------------------------------------------------------"
echo "kubectl -n $NAMESPACE get all,ingress,Middleware"
echo 

ipa=$(kubectl -n toolbox-lb get svc toolbox -o json | jq -r '.status.loadBalancer.ingress[].ip') 

echo " ▪ Test Application for Domain: $TLS_INGRESS_APPINT_DOMAIN and $TLS_INGRESS_APPADC_DOMAIN"
echo "   => curl http://${ipa}:$EXPOSE_PORT"
echo ""
echo " ▪ Connect to the docker container"
echo "   => kubectl -n $NAMESPACE exec -it \$(kubectl get pod -n $NAMESPACE -l app=toolbox -o jsonpath='{.items[0].metadata.name}') -- /bin/sh"
echo "   => kubectl -n $NAMESPACE exec -it \$(kubectl get pod -n $NAMESPACE -l app=toolbox -o jsonpath='{.items[0].metadata.name}') -- /bin/sh -c \"while [ 1 ]; do clear; netstat -t && sleep 1; done\""

echo ""

