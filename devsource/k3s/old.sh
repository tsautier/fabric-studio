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
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '             Configure an Server Loadbalancer on a FortiADC with Ansible Playbook     '
echo '                                  by Sacha Dubois, Fortinet Inc                       '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# Cleanup from last deployment
#getObject $NAMESPACE ingress ${APPNAME}-fortidemo && kubectl -n $NAMESPACE delete ingress ${APPNAME}-fortidemo > /dev/null 2>&1
getObject $NAMESPACE svc my-sise && kubectl -n $NAMESPACE delete svc my-sise > /dev/null 2>&1
getObject $NAMESPACE deployment my-sise && kubectl -n $NAMESPACE delete deployment my-sise > /dev/null 2>&1
#getObject $NAMESPACE secret $TLS_INGRESS_APPINT_SECRET && kubectl -n $NAMESPACE delete secret $TLS_INGRESS_APPINT_SECRET > /dev/null 2>&1
getObject $NAMESPACE namespace $NAMESPACE && kubectl delete ns $NAMESPACE > /dev/null 2>&1

cat <<EOF > $TMPDIR/service-my-sise.yaml
kind: Service
apiVersion: v1
metadata:
  name: service1
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

cat <<EOF > $TMPDIR/deployment-my-sise.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-sise
  labels:
    run: my-sise
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

prtHead "Create the kubernetes Namespace: fadcdemo"
execCmd "kubectl create ns fadcdemo"
execCmd "kubectl get ns"
#dockerPullSecret $NAMESPACE > /dev/null 2>&1

prtHead "Create Secret with FortiADC Access Parameters"
execCmd "kubectl create secret generic fad-login -n $NAMESPACE \\
        --from-literal=username=admin --from-literal=password='F0rt!net'"

prtHead "Create Deployment (my-web)"
execCat "$TMPDIR/deployment-my-web.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/deployment-my-sise.yaml"
kubectl -n fadcdemo wait --for=condition=Ready pod -l run=sise --timeout=300s > /dev/null 2>&1
execCmd "kubectl -n fadcdemo get pods,deployment"

prtHead "Create Service (my-web) type NodePort"
execCat "$TMPDIR/service-my-web.yaml"
execCmd "kubectl -n fadcdemo apply -f $TMPDIR/service-my-sise.yaml"
execCmd "kubectl -n fadcdemo get pods,deployment.svc"

exit
