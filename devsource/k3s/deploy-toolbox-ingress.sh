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

[ "$ADC_INGRESS" == "" ] && ADC_INGRESS=1
NAMESPACE=toolbox
APPNAME=toolbox
APPDESC="ToolsBox Demo"
DOCKER_IMAGE=sadubois/toolbox:latest
CONTAINER_PORT=8080
EXPOSE_PORT=8080
SERVICE_TYPE=ClusterIP
TLS_FORTIDEMO_CA_CERT=ca.crt
TLS_FORTIDEMO_CERTPATH=$HOME/cert/fortidemo

# Traefic Ingress Condfiguraiton
TLS_INGRESS_APPINT_CERTNAME=k3s-apps-internal
TLS_INGRESS_APPINT_SECRET=fortidemo-appint-tls-cert
TLS_INGRESS_APPINT_EXPRIRE=$(openssl x509 -in $TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPINT_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')
TLS_INGRESS_APPINT_DOMAIN=apps-int.fortidemo.net
TLS_INGRESS_APPINT_IPADDR=$(dig +short $APPNAME.$TLS_INGRESS_APPINT_DOMAIN)

# FortiADC Ingress Configuration
TLS_INGRESS_APPADC_CERTNAME=k3s-apps-adc-toolbox
TLS_INGRESS_APPADC_SECRET=fortidemo-appadc-tls-cert
TLS_INGRESS_APPADC_EXPRIRE=$(openssl x509 -in $TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')
TLS_INGRESS_APPADC_DOMAIN=apps-adc.fortidemo.net
TLS_INGRESS_APPADC_IPADDR=$(dig +short $APPNAME.$TLS_INGRESS_APPADC_DOMAIN)

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $HOME/workspace/tanzu-demo-hub/functions ] && . $HOME/workspace/tanzu-demo-hub/functions

if [ "$1" == "delete" -o "$1" == "delete" ]; then 
  echo "=> Undeploy '$APPDESC' Deployment ($APPNAME)"
  kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo
  [ $ADC_INGRESS -eq 1 ] && kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo-adc
  kubectl -n $NAMESPACE delete svc $APPNAME
  kubectl -n $NAMESPACE delete deployment $APPNAME
  kubectl -n $NAMESPACE delete secret $TLS_INGRESS_APPINT_SECRET
  kubectl -n $NAMESPACE delete secret $TLS_INGRESS_APPADC_SECRET
  kubectl -n $NAMESPACE delete secret $APPNAME-sa-token
  kubectl -n $NAMESPACE delete serviceaccount $APPNAME-sa
  kubectl delete ns $NAMESPACE
  echo "$APPDESC undeployed successfuully"

  exit
fi

echo "=> Deploy '$APPDESC' Deployment ($APPNAME)"
echo " ▪ Create / update namespace $NAMESPACE"
kubectl create ns $NAMESPACE > /dev/null 2>&1

echo " ▪ Create a docker pull secret"
dockerPullSecret $NAMESPACE > /dev/null 2>&1

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

echo " ▪ Create TLS Certificate secret ($TLS_INGRESS_APPINT_SECRET) Expiring: $TLS_INGRESS_APPINT_EXPRIRE"
nam=$(kubectl get secrets -n $NAMESPACE -o json | jq -r --arg key "$TLS_INGRESS_APPINT_SECRET" '.items[].metadata | select(.name == $key).name' )
if [ "$nam" == "" ]; then 
  kubectl create secret tls $TLS_INGRESS_APPINT_SECRET \
    --namespace $NAMESPACE \
    --cert="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPINT_CERTNAME}.crt" \
    --key="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPINT_CERTNAME}.key"
fi

if [ $ADC_INGRESS -eq 1 ]; then
  echo " ▪ Create Secret with FortiADC Access Parameters"
  kubectl create secret generic fad-login -n $NAMESPACE \
  --from-literal=username=admin --from-literal=password='F0rt!net' > /dev/null 2>&1

  echo " ▪ Create TLS Certificate secret ($TLS_INGRESS_APPADC_SECRET) Expiring: $TLS_INGRESS_APPADC_EXPRIRE"
  nam=$(kubectl get secrets -n $NAMESPACE -o json | jq -r --arg key "$TLS_INGRESS_APPADC_SECRET" '.items[].metadata | select(.name == $key).name' )
  if [ "$nam" == "" ]; then
    kubectl create secret tls $TLS_INGRESS_APPADC_SECRET \
      --namespace $NAMESPACE \
      --cert="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt" \
      --key="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.key"
  fi
fi

echo " ▪ Create Ingress Resource for $APPNAME for Domain: $TLS_INGRESS_APPINT_DOMAIN"
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

if [ $ADC_INGRESS -eq 1 ]; then
  echo " ▪ Create Ingress Resource for $APPNAME for Domain: $TLS_INGRESS_APPADC_DOMAIN"
cat <<EOF | kubectl -n $NAMESPACE apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APPNAME}-fortidemo-adc
  annotations: {
    "virtual-server-ip" : "$TLS_INGRESS_APPADC_IPADDR",
    "virtual-server-interface" : "port2",
    "fortiadc-ip" : "10.1.1.3",
    "fortiadc-login" : "fad-login",
    "fortiadc-ctrl-log" : "enable",
    "virtual-server-fortiview" : "enable",
    "virtual-server-traffic-log" : "enable",
    "fortiadc-vdom" : "root"
  }
spec:
  ingressClassName:  fadc-ingress-controller
  tls:
  - secretName: $TLS_INGRESS_APPADC_SECRET   # Secret containing the TLS certificate
    hosts:
    - "*.$TLS_INGRESS_APPADC_DOMAIN"     # Wildcard domain covered by the certificate
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
fi


# Create Service Account
kubectl create serviceaccount $APPNAME-sa -n $NAMESPACE

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $APPNAME-sa-token
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: "$APPNAME-sa"
type: kubernetes.io/service-account-token
EOF

# Create ClusterRole
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $APPNAME-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "nodes"]
  verbs: ["get", "watch", "list"]
EOF

# Create ClusterRoleBindeing
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $APPNAME-rolebinding
subjects:
- kind: ServiceAccount
  name: $APPNAME-sa
  namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: $APPNAME-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl -n $NAMESPACE wait --for=condition=Ready pod -l app=$APPNAME --timeout=300s

echo " ▪ Show Deployment"
echo "----------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE get all,ingress,Middleware,sa,secret
echo "----------------------------------------------------------------------------------------------------------------"
echo "kubectl -n $NAMESPACE get all,ingress,Middleware"
echo 

echo " ▪ Test Application for Domain: $TLS_INGRESS_APPINT_DOMAIN and $TLS_INGRESS_APPADC_DOMAIN"
echo "   => curl https://$APPNAME.$TLS_INGRESS_APPINT_DOMAIN --cacert $TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT"
echo "   => curl https://$APPNAME.$TLS_INGRESS_APPADC_DOMAIN --cacert $TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT"
echo ""
echo " ▪ Get the Kubernetes Security Token for Namesapce $$NAMESPACE"
echo "   => kubectl get secret $APPNAME-sa-token -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d && echo"
echo ""
echo " ▪ Connect to the docker container"
echo "   => kubectl -n toolbox exec -it \$(kubectl get pod -n toolbox -l app=toolbox -o jsonpath='{.items[0].metadata.name}') -- /bin/sh"
echo "      curl https://fortinet.com --proxy proxy.fabric-studio.fortidemo.ch:8080"
echo ""

