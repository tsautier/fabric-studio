#!/bin/bash
# ============================================================================================
# File: ........: deploy-echoserver-ingress-fadc-nodeport-guided.sh
# Demo Package .: fortiadc-slb-employdb-ansible
# Language .....: bash
# Author .......: Sacha Dubois, Fortinet
# --------------------------------------------------------------------------------------------
# Category .....: Ansible
# Description ..: Deploy SLB on FortiADC with Ansible
# ============================================================================================

getObject() {
  local NAMESPACE="$1"
  local OBJ="$2"
  local KEY="$3"
  kubectl -n $NAMESPACE get $OBJ -o jsonpath="{.items[?(@.metadata.name==\"$KEY\")].metadata.name}" | grep -q "$KEY"
}

[ -f $HOME/functions ] && source $HOME/functions

# --- SETTING FOR TDH-TOOLS ---
NAMESPACE=fadcdemo
TMPDIR=/tmp
APPNAME=fadcdemo

# FortiADC Ingress Configuration
TLS_FORTIDEMO_CERTPATH=$HOME/cert/fortidemo
TLS_INGRESS_APPADC_CERTNAME=k3s-apps-adc-$APPNAME
TLS_INGRESS_APPADC_SECRET=fortidemo-appadc-tls-cert
TLS_INGRESS_APPADC_EXPRIRE=$(openssl x509 -in $TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt -noout -dates | tail -1 | sed 's/^.*=//g')
TLS_INGRESS_APPADC_DOMAIN=apps-adc.fortidemo.net
TLS_INGRESS_APPADC_IPADDR=$(dig +short $APPNAME.$TLS_INGRESS_APPADC_DOMAIN)

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

# Created by /usr/local/bin/figlet
clear
echo '                            _____          _   _    _    ____   ____                      '
echo '                           |  ___|__  _ __| |_(_)  / \  |  _ \ / ___|                     '
echo '                           | |_ / _ \|  __| __| | / _ \ | | | | |                         '
echo '                           |  _| (_) | |  | |_| |/ ___ \| |_| | |___                      '
echo '                           |_|  \___/|_|   \__|_/_/   \_\____/ \____|                     '
echo '                                                                                          '
echo '                 ___                                 ____                                 '
echo '                |_ _|_ __   __ _ _ __ ___  ___ ___  |  _ \  ___ _ __ ___   ___            '
echo '                 | ||  _ \ / _  |  __/ _ \/ __/ __| | | | |/ _ \  _   _ \ / _ \           '
echo '                 | || | | | (_| | | |  __/\__ \__ \ | |_| |  __/ | | | | | (_) |          '
echo '                |___|_| |_|\__, |_|  \___||___/___/ |____/ \___|_| |_| |_|\___/           '
echo '                           |___/                                                          '
echo '                                                                                          '
echo '          ----------------------------------------------------------------------------    '
echo '                       Deploy FortiADC Ingress Controller with NodePort Demo              '
echo '                                  by Sacha Dubois, Fortinet Inc                           '
echo '          ----------------------------------------------------------------------------    '
echo '                                                                                          '

# Cleanup from last deployment
getObject $NAMESPACE ingress $APPNAME && kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo > /dev/null 2>&1
getObject $NAMESPACE svc sise && kubectl -n $NAMESPACE delete svc sise > /dev/null 2>&1
getObject $NAMESPACE svc nginx && kubectl -n $NAMESPACE delete svc nginx > /dev/null 2>&1
getObject $NAMESPACE deployment sise && kubectl -n $NAMESPACE delete deployment sise > /dev/null 2>&1
getObject $NAMESPACE deployment nginx && kubectl -n $NAMESPACE delete deployment nginx > /dev/null 2>&1
getObject $NAMESPACE secret $TLS_INGRESS_APPINT_SECRET && kubectl -n $NAMESPACE delete secret $TLS_INGRESS_APPINT_SECRET > /dev/null 2>&1
getObject $NAMESPACE secret fad-login && kubectl -n $NAMESPACE delete secret fad-login > /dev/null 2>&1
getObject $NAMESPACE namespace $NAMESPACE && kubectl delete ns $NAMESPACE > /dev/null 2>&1

cat <<EOF > $TMPDIR/service-sise.yaml
kind: Service
apiVersion: v1
metadata:
  name: sise
  annotations: {
    "health-check-ctrl" : "enable",
    "health-check-relation" : "OR",
    "health-check-list" : "LB_HLTHCK_ICMP",
    "real-server-ssl-profile" : "NONE"
  }
spec:
  type: NodePort
  ports:
  - port: 1241
    protocol: TCP
    targetPort: 9876
  selector:
    run: sise
  sessionAffinity: None
EOF

cat <<EOF > $TMPDIR/deployment-sise.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sise
  labels:
    run: sise
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: sise
    spec:
      containers:
        - name: sise
          image: mhausenblas/simpleservice:0.5.0
          ports:
            - containerPort: 9876
              name: sise-default
  selector:
    matchLabels:
      run: sise
EOF

cat <<EOF > $TMPDIR/deployment-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - name: nginx
        image: nginxdemos/hello
        ports:
        - containerPort: 80
EOF


cat <<EOF > $TMPDIR/service-nginx.yaml
kind: Service
apiVersion: v1
metadata:
  name: nginx
  annotations: {
    "health-check-ctrl" : "enable",
    "health-check-relation" : "OR",
    "health-check-list" : "LB_HLTHCK_ICMP",
    "real-server-ssl-profile" : "NONE"
  }
spec:
  type: NodePort
  ports:
  - port: 1242
    protocol: TCP
    targetPort: 80
  selector:
    run: nginx
  sessionAffinity: None
EOF

cat <<EOF > $TMPDIR/fadc-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APPNAME
  annotations: {
    "fortiadc-ip" : "10.1.1.3",
    "fortiadc-login" : "fad-login",
    "fortiadc-vdom" : "root",
    virtual-server-fortiview: enable, 
    "fortiadc-ctrl-log" : "enable",
    "virtual-server-ip" : "$TLS_INGRESS_APPADC_IPADDR",
    "virtual-server-interface" : "port2",
    "virtual-server-port" : "443",
    "load-balance-method" : "LB_METHOD_LEAST_CONNECTION",
    "load-balance-profile" : "LB_PROF_HTTPS"
  }
spec:
  ingressClassName: fadc-ingress-controller
  tls:
  - secretName: $TLS_INGRESS_APPADC_SECRET
    hosts:
    - "$APPNAME.$TLS_INGRESS_APPADC_DOMAIN"
  rules:
  - host: ${APPNAME}.$TLS_INGRESS_APPADC_DOMAIN
    http:
      paths:
      - path: /info
        pathType: Prefix
        backend:
          service:
            name: sise
            port:
              number: 1241
      - path: /hello
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 1242
EOF

prtHead "Create the kubernetes Namespace: fadcdemo"
execCmd "kubectl create ns fadcdemo"
execCmd "kubectl get ns"
#dockerPullSecret $NAMESPACE > /dev/null 2>&1

prtHead "Create Secret with FortiADC Access Parameters"
execCmd "kubectl create secret generic fad-login -n $NAMESPACE \\
        --from-literal=username=admin --from-literal=password='F0rt!net'" 

prtHead "Create TLS Certificate secret ($TLS_INGRESS_APPADC_SECRET) Expiring: $TLS_INGRESS_APPADC_EXPRIRE"
execCmd "kubectl create secret tls $TLS_INGRESS_APPADC_SECRET \\
        --namespace $NAMESPACE \\
        --cert=\"$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt\" \\
        --key=\"$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.key\""

prtHead "Create Deployment and service for (my-web)"
execCat "$TMPDIR/deployment-sise.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/deployment-sise.yaml"
sleep 1
kubectl -n fadcdemo wait --for=condition=Ready pod -l run=nginx --timeout=300s > /dev/null 2>&1
execCat "$TMPDIR/service-sise.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/service-sise.yaml"
execCmd "kubectl -n fadcdemo get pods,deployment,svc"

prtHead "Create Deployment and service for (nginx)"
execCat "$TMPDIR/deployment-nginx.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/deployment-nginx.yaml"
sleep 1
kubectl -n fadcdemo wait --for=condition=Ready pod -l run=sise --timeout=300s > /dev/null 2>&1
execCat "$TMPDIR/service-nginx.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/service-nginx.yaml"
execCmd "kubectl -n fadcdemo get pods,deployment,svc"

prtHead "Deploy FortiADC Ingress"
execCat "$TMPDIR/fadc-ingress.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/fadc-ingress.yaml"
execCmd "kubectl -n fadcdemo get pods,deployment,svc,ingress"
execCmd "kubectl -n fadcdemo describe ingress $APPNAME"

prtHead "Show Configuration on the FortiADC"
slntCmd "echo 'F0rt!net' > /tmp/passwd"
execCmd "sshpass -f /tmp/passwd ssh admin@10.1.1.3 -n \"show load-balance virtual-server fadcdemo_fadcdemo\""
execCmd "sshpass -f /tmp/passwd ssh admin@10.1.1.3 -n \"show load-balance pool fadcdemo_sise\""
execCmd "sshpass -f /tmp/passwd ssh admin@10.1.1.3 -n \"show load-balance pool fadcdemo_nginx\""
execCmd "sshpass -f /tmp/passwd ssh admin@10.1.1.3 -n \"show load-balance real-server debk3s\""

prtHead "Show Configuration on the FortiADC in FortiView"
prtText "Navigate to FortiADC -> FortiView -> Topology"
echo ""                          

prtText "Open WebBrowser and verify the the application"
echo "     => https://fadcdemo.$TLS_INGRESS_APPADC_DOMAIN/info"
echo "     => https://fadcdemo.$TLS_INGRESS_APPADC_DOMAIN/hello"
echo ""
prtText "Verify the the application from the CLI"
echo "     => curl https://fadcdemo.$TLS_INGRESS_APPADC_DOMAIN/info --cacert /home/fortinet/cert/fortidemo/ca.crt | jq -r"
echo "     => curl https://fadcdemo.$TLS_INGRESS_APPADC_DOMAIN/hello --cacert /home/fortinet/cert/fortidemo/ca.crt | lynx -stdin -dump"
echo ""


echo -e "     Press 'return' to continue \c\b"; read x
echo ""

exit
