#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-edb-ingress.sh
# DESCRIPTION:    Deploy Fortinet EmployeeDB Application
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-30
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-30 sdubois Initial version
#===============================================================================

export NAMESPACE=edb
export APPNAME=edb
export APPDESC="EmployeeDB Demo"
export DOCKER_IMAGE=sadubois/employeedb:1.4.1
export CONTAINER_PORT=8080
export EXPOSE_PORT=80
export SERVICE_TYPE=ClusterIP
export TLS_FORTIDEMO_CERTPATH=$HOME/cert/fortidemo
export TLS_FORTIDEMO_CERTNAME=fabric
export TLS_FORTIDEMO_SECRET=fortidemo-tls-cert
export TLS_FORTIDEMO_EXPRIRE=$(openssl x509 -in $TLS_FORTIDEMO_CERTPATH/${TLS_FORTIDEMO_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')
export DNS_DOMAIN_FORTIDEMO=fabric.fortidemo.ch

#export DNS_DOMAIN_CORELAB=apps.tkg.corelab.core-software.ch
#export TLS_CORELAB_CERTPATH=$HOME/Documents/Certificate/STAR.apps.tkg.corelab.core-software.ch
#export TLS_CORELAB_CERTNAME=k8s-apps-core
#export TLS_CORELAB_SECRET=core-tls-secret
#export TLS_CORELAB_EXPRIRE=$(openssl x509 -in $TLS_CORELAB_CERTPATH/${TLS_CORELAB_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $HOME/workspace/tanzu-demo-hub/functions ] && . $HOME/workspace/tanzu-demo-hub/functions

if [ "$1" == "delete" -o "$1" == "delete" ]; then 
  echo "=> Undeploy '$APPDESC' Deployment ($APPNAME)"
  #kubectl -n $NAMESPACE delete ingress ${APPNAME}-corelab
  kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo
  kubectl -n $NAMESPACE delete svc $APPNAME
  kubectl -n $NAMESPACE delete deployment $APPNAME
  kubectl -n $NAMESPACE delete secret fortidemo-tls-cert 
  #kubectl -n $NAMESPACE delete secret core-tls-secret
  kubectl delete ns $NAMESPACE
  echo "$APPDESC undeployed successfuully"

  exit
fi


echo "=> Deploy '$APPDESC' Deployment ($APPNAME)"
echo " ▪ Create / update namespace $NAMESPACE"
kubectl create ns $NAMESPACE > /dev/null 2>&1

echo " ▪ Create a docker pull secret"
dockerPullSecret $NAMESPACE > /dev/null 2>&1

nam=$(kubectl get secrets -n $NAMESPACE -o json | jq -r --arg key "mysql-credentials" '.items[].metadata | select(.name == $key).name' )
if [ "$nam" == "" ]; then
  echo " ▪ Create a datasource secret for the MySQL backend"
  kubectl create secret generic mysql-credentials \
          --from-literal=spring.datasource.username=admin \
          --from-literal=spring.datasource.password=fortinet \
          --namespace $NAMESPACE > /dev/null 2>&1
fi

echo " ▪ Create Deployment"
cat <<EOF | kubectl -n $NAMESPACE  apply -f -
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
          - name: SPRING_PROFILES_ACTIVE
            value: "fabric-studio"
          - name: SPRING_DATASOURCE_USERNAME
            valueFrom:
              secretKeyRef:
                name: mysql-credentials
                key: spring.datasource.username
          - name: SPRING_DATASOURCE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mysql-credentials
                key: spring.datasource.password
        resources:
          limits:
            memory: "4Gi"
            cpu: "1"
          requests:
            memory: "1Gi"
            cpu: "300m"
EOF

echo " ▪ Expose Container Port: $CONTAINER_PORT to $EXPOSE_PORT service Type: $SERVICE_TYPE"
cat <<EOF | kubectl -n $NAMESPACE apply -f -
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

if [ "$nam" == "" ]; then 
  echo " ▪ Create TLS Certificate secret ($TLS_FORTIDEMO_SECRET) Expiring: $TLS_FORTIDEMO_EXPRIRE"
  nam=$(kubectl get secrets -n $NAMESPACE -o json | jq -r --arg key "$TLS_CORELAB_SECRET" '.items[].metadata | select(.name == $key).name' )
  kubectl create secret tls $TLS_FORTIDEMO_SECRET \
    --namespace $NAMESPACE \
    --cert=$TLS_FORTIDEMO_CERTPATH/${TLS_FORTIDEMO_CERTNAME}.crt \
    --key=$TLS_FORTIDEMO_CERTPATH/${TLS_FORTIDEMO_CERTNAME}.key
fi

echo " ▪ Create Ingress Resource for $APPNAME for Domain: $DNS_DOMAIN_FORTIDEMO"
cat <<EOF | kubectl -n $NAMESPACE apply -f -
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
  - secretName: $TLS_FORTIDEMO_SECRET   # Secret containing the TLS certificate
    hosts:
    - "*.$DNS_DOMAIN_FORTIDEMO"     # Wildcard domain covered by the certificate
  rules:
  - host: ${APPNAME}.$DNS_DOMAIN_FORTIDEMO   # Your specific hostname
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

echo " ▪ Show Deployment"
echo "----------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE get all,ingress,Middleware
echo "----------------------------------------------------------------------------------------------------------------"
echo "kubectl -n $NAMESPACE get all,ingress,Middleware"
echo 

echo " ▪ Test Application for Domain: $DNS_DOMAIN_FORTIDEMO"
echo "   curl https://$APPNAME.$DNS_DOMAIN_FORTIDEMO --cacert $TLS_FORTIDEMO_CERTPATH/fortidemoCA.crt"
echo ""

#openssl x509 -in k3s-apps-instern.crt -text -noout



