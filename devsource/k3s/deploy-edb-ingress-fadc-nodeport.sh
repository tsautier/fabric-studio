#!/bin/bash
#===============================================================================
# SCRIPT NAME:    deploy-edb-ingress-fadc-nodeport.sh
# DESCRIPTION:    Deploy Fortinet EmployeeDB Application (SAML, LDAPS health)
# AUTHOR:         Sacha Dubois, Fortinet (+ ChatGPT tweaks)
# CREATED:        2025-03-30
# VERSION:        1.2
#===============================================================================
# CHANGE LOG:
# 2025-03-30 sdubois Initial version
# 2025-07-06 sdubois Added FortiADC Ingress
# 2025-10-15 chatgpt  Add PKIX truststore, SAML fixes
# 2025-10-16 chatgpt  Add LDAP bind secret + LDAPS health
#===============================================================================

set -euo pipefail

# -------------------- Tunables --------------------
[ "${ADC_INGRESS:-}" == "" ] && ADC_INGRESS=1
NAMESPACE=edb-ingress-fadc
APPNAME=edb
APPDESC="EmployeeDB Demo"
DOCKER_IMAGE=sadubois/employeedb:1.5.1
CONTAINER_PORT=8080
EXPOSE_PORT=80
SERVICE_TYPE=ClusterIP

# FortiDemo CA
TLS_FORTIDEMO_CA_CERT=ca.crt
TLS_FORTIDEMO_CERTPATH=${TLS_FORTIDEMO_CERTPATH:-$HOME/cert/fortidemo}

# Ingress (FortiADC)
TLS_INGRESS_APPADC_CERTNAME=k3s-apps-adc-edb
TLS_INGRESS_APPADC_SECRET=fortidemo-appadc-tls-cert
TLS_INGRESS_APPADC_EXPRIRE=$(openssl x509 -in "$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt" -noout -dates | tail -1 | sed 's/^.*=//g')
TLS_INGRESS_APPADC_DOMAIN=apps-adc.fortidemo.net
TLS_INGRESS_APPADC_IPADDR=$(dig +short "$APPNAME.$TLS_INGRESS_APPADC_DOMAIN")

# DB-Access credentials
DB_SERVER=10.1.2.201
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=fortinet

# -------------------- SAML (IdP) --------------------
IDP_PREFIX=edbadc
IDP_METADATA_URI="https://fortiauth.fortidemo.net/saml-idp/${IDP_PREFIX}/metadata/"
IDP_LOGOUT_URL="https://fortiauth.fortidemo.net/saml-idp/${IDP_PREFIX}/logout/"

RELYING_ENTITY_ID="${APPNAME}.${TLS_INGRESS_APPADC_DOMAIN}"
SERVER_BASE_URL="https://${APPNAME}.${TLS_INGRESS_APPADC_DOMAIN}"

# Secret containing the IdP CA (already used by truststore init)
IDP_CA_SECRET_NAME=idp-ca
IDP_CA_KEY_NAME=$TLS_FORTIDEMO_CA_CERT  # ca.crt on disk -> key name in secret

# -------------------- LDAP/LDAPS Health --------------------
LDAP_BIND_SECRET=ldap-credentials
LDAP_BIND_DN_KEY=bind_dn
LDAP_BIND_PW_KEY=bind_password
LDAP_PASSWORD='F0rt!net'
LDAP_BIND_DN='uid=healthcheck,ou=Users,dc=fortidemo,dc=net'

# LDAPS endpoint
LDAP_URL="ldaps://fortiauth.fortidemo.net:636"
LDAP_BASE="dc=fortidemo,dc=net"

# -----------------------------------------------------------
[ -f "$HOME/.tanzu-demo-hub.cfg" ] && . "$HOME/.tanzu-demo-hub.cfg"
[ -f "$HOME/workspace/tanzu-demo-hub/functions" ] && . "$HOME/workspace/tanzu-demo-hub/functions"

if [ "${1:-}" == "delete" ]; then
  echo "=> Undeploy '$APPDESC' Deployment ($APPNAME)"
  kubectl -n "$NAMESPACE" delete ingress "${APPNAME}-fortidemo-adc" --ignore-not-found
  kubectl -n "$NAMESPACE" delete svc "$APPNAME" --ignore-not-found
  kubectl -n "$NAMESPACE" delete deployment "$APPNAME" --ignore-not-found
  kubectl -n "$NAMESPACE" delete secret "$TLS_INGRESS_APPADC_SECRET" --ignore-not-found
  kubectl -n "$NAMESPACE" delete secret "$IDP_CA_SECRET_NAME" --ignore-not-found
  kubectl -n "$NAMESPACE" delete secret "$LDAP_BIND_SECRET" --ignore-not-found
  kubectl delete ns "$NAMESPACE" --ignore-not-found
  echo "$APPDESC undeployed successfully"
  exit 0
fi

echo "=> Deploy '$APPDESC' Deployment ($APPNAME)"
echo " ▪ Create / update namespace $NAMESPACE"
kubectl create ns "$NAMESPACE" >/dev/null 2>&1 || true

echo " ▪ Create a docker pull secret"
dockerPullSecret "$NAMESPACE" >/dev/null 2>&1 || true

echo " ▪ Create datasource secret for the MySQL backend (if missing)"
if ! kubectl get secret -n "$NAMESPACE" mysql-credentials >/dev/null 2>&1; then
  kubectl create secret generic mysql-credentials \
    --from-literal=spring.datasource.username="$DB_USER" \
    --from-literal=spring.datasource.password="$DB_PASSWORD" \
    --namespace "$NAMESPACE" >/dev/null
fi

echo " ▪ Ensure IdP CA secret ($IDP_CA_SECRET_NAME) exists"
kubectl -n "$NAMESPACE" create secret generic "$IDP_CA_SECRET_NAME" \
  --from-file="$IDP_CA_KEY_NAME=$TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT" \
  --dry-run=client -o yaml | kubectl apply -f -

echo " ▪ Ensure LDAP bind secret ($LDAP_BIND_SECRET) exists"
kubectl -n "$NAMESPACE" create secret generic "$LDAP_BIND_SECRET" \
  --from-literal="$LDAP_BIND_DN_KEY=$LDAP_BIND_DN" \
  --from-literal="$LDAP_BIND_PW_KEY=$LDAP_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo " ▪ Create / Update Deployment"
cat <<EOF | kubectl -n "$NAMESPACE" apply -f -
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
      # -------------------- Init: build PKCS12 truststore with IdP CA --------------------
      initContainers:
        - name: build-truststore
          image: eclipse-temurin:21-jre
          command: ["/bin/sh","-c"]
          args:
            - |
              set -e
              ls -l /certs
              keytool -importcert -trustcacerts -noprompt \
                -alias idp-ca \
                -keystore /work/truststore.p12 \
                -storetype PKCS12 \
                -storepass changeit \
                -file /certs/$IDP_CA_KEY_NAME
              keytool -list -keystore /work/truststore.p12 -storepass changeit | grep -i idp-ca
          volumeMounts:
            - { name: truststore, mountPath: /work }
            - { name: idp-ca, mountPath: /certs, readOnly: true }

      containers:
        - name: $APPNAME
          image: $DOCKER_IMAGE
          ports:
            - containerPort: $CONTAINER_PORT

          env:
            # --- DB ---
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
            - name: SPRING_DATASOURCE_URL
              value: jdbc:mysql://$DB_SERVER:$DB_PORT/employeedb?createDatabaseIfNotExist=true

            # --- Profile ---
            - name: SPRING_PROFILES_ACTIVE
              value: "fabric-studio"

            # --- SAML mode ---
            - name: EDB_AUTHENTICATION
              value: "saml"
            - name: SERVER_BASE_URL
              value: "$SERVER_BASE_URL"
            - name: EDB_SAML_ENTITY_ID
              value: "$RELYING_ENTITY_ID"
            - name: EDB_SAML_IDP_METADATA_URI
              value: "$IDP_METADATA_URI"
            - name: EDB_SAML_IDP_LOGOUT_URL
              value: "$IDP_LOGOUT_URL"
            - name: EDB_SAML_POST_LOGOUT_REDIRECT
              value: "/"

            - name: SERVER_FORWARD_HEADERS_STRATEGY
              value: framework
            - name: SERVER_SERVLET_SESSION_COOKIE_SECURE
              value: "true"
            - name: SERVER_SERVLET_SESSION_COOKIE_SAMESITE
              value: "LAX"

            # Spring Security relaxed-binding equivalents
            - name: SPRING_SECURITY_SAML2_RELYINGPARTY_REGISTRATION_FORTIAUTH_ASSERTINGPARTY_METADATA_URI
              value: "$IDP_METADATA_URI"
            - name: SPRING_SECURITY_SAML2_RELYINGPARTY_REGISTRATION_FORTIAUTH_ENTITY_ID
              value: "$RELYING_ENTITY_ID"
            - name: SPRING_SECURITY_SAML2_RELYINGPARTY_REGISTRATION_FORTIAUTH_ASSERTION_CONSUMER_SERVICE_LOCATION
              value: "$SERVER_BASE_URL/login/saml2/sso/fortiauth"

            # --- LDAPS for health check (and any LDAP usage) ---
            - name: SPRING_LDAP_URLS
              value: "$LDAP_URL"
            - name: SPRING_LDAP_BASE
              value: "$LDAP_BASE"
            - name: SPRING_LDAP_USERNAME
              valueFrom:
                secretKeyRef:
                  name: $LDAP_BIND_SECRET
                  key: $LDAP_BIND_DN_KEY
            - name: SPRING_LDAP_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: $LDAP_BIND_SECRET
                  key: $LDAP_BIND_PW_KEY

            # --- Logging (optional) ---
            - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY_SAML2
              value: "DEBUG"
            - name: LOGGING_LEVEL_ORG_SPRINGSECURITY
              value: "DEBUG"
            - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY
              value: "DEBUG"

            # --- Java truststore path to include our IdP CA (also used by LDAPS) ---
            - name: JAVA_TOOL_OPTIONS
              value: "-Djavax.net.ssl.trustStore=/app/trust/truststore.p12 -Djavax.net.ssl.trustStorePassword=changeit"

          volumeMounts:
            - { name: truststore, mountPath: /app/trust }

          resources:
            limits:
              memory: "4Gi"
              cpu: "1"
            requests:
              memory: "1Gi"
              cpu: "300m"

      volumes:
        - name: truststore
          emptyDir: {}
        - name: idp-ca
          secret:
            secretName: $IDP_CA_SECRET_NAME
EOF

echo " ▪ Expose Container Port: $CONTAINER_PORT to $EXPOSE_PORT service Type: $SERVICE_TYPE"
cat <<EOF | kubectl -n "$NAMESPACE" apply -f -
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

echo " ▪ Create Secret with FortiADC Access Parameters"
kubectl create secret generic fad-login -n "$NAMESPACE" \
  --from-literal=username=admin --from-literal=password='F0rt!net' >/dev/null 2>&1 || true

echo " ▪ Create TLS Certificate secret ($TLS_INGRESS_APPADC_SECRET) Expiring: $TLS_INGRESS_APPADC_EXPRIRE"
if ! kubectl get secret -n "$NAMESPACE" "$TLS_INGRESS_APPADC_SECRET" >/dev/null 2>&1; then
  kubectl create secret tls "$TLS_INGRESS_APPADC_SECRET" \
    --namespace "$NAMESPACE" \
    --cert="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.crt" \
    --key="$TLS_FORTIDEMO_CERTPATH/${TLS_INGRESS_APPADC_CERTNAME}.key"
fi

echo " ▪ Create Ingress Resource (FortiADC) for Domain: $TLS_INGRESS_APPADC_DOMAIN"
cat <<EOF | kubectl -n "$NAMESPACE" apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APPNAME}-fortidemo-adc
  annotations:
    virtual-server-ip: "$TLS_INGRESS_APPADC_IPADDR"
    virtual-server-interface: "port2"
    fortiadc-ip: "10.1.1.3"
    fortiadc-login: "fad-login"
    fortiadc-ctrl-log: "enable"
    virtual-server-fortiview: "enable"
    virtual-server-traffic-log: "enable"
    load-balance-profile: "LB_PROF_HTTPS_SAML"
    fortiadc-vdom: "root"
spec:
  ingressClassName: fadc-ingress-controller
  tls:
    - secretName: $TLS_INGRESS_APPADC_SECRET
      hosts:
        - "*.$TLS_INGRESS_APPADC_DOMAIN"
  rules:
    - host: ${APPNAME}.$TLS_INGRESS_APPADC_DOMAIN
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
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod -l app="$APPNAME" --timeout=300s || true

# Pod + Service
echo " ▪ Patch for Deploy an echo pod/service and route a path"
kubectl -n edb-ingress-fadc apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: header-echo
  labels: { app: header-echo }
spec:
  containers:
    - name: echo
      image: ghcr.io/mendhak/http-https-echo:30
      ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Service
metadata:
  name: header-echo
spec:
  selector: { app: header-echo }
  ports:
    - name: http
      port: 80
      targetPort: 8080
YAML

# Add an extra rule on your FortiADC Ingress to /debug/headers
kubectl -n edb-ingress-fadc patch ingress edb-fortidemo-adc --type='json' -p='[
  {"op":"add","path":"/spec/rules/0/http/paths/-","value":{
    "path":"/debug/headers",
    "pathType":"Prefix",
    "backend":{"service":{"name":"header-echo","port":{"number":80}}}
  }}
]'

echo " ▪ Show Deployment"
echo "----------------------------------------------------------------------------------------------------------------"
kubectl -n "$NAMESPACE" get all,ingress
echo "----------------------------------------------------------------------------------------------------------------"
echo "kubectl -n $NAMESPACE get all,ingress"
echo
echo " ▪ Test Application for Domains:"
echo "   => curl -I https://$APPNAME.$TLS_INGRESS_APPADC_DOMAIN/employees/list --cacert $TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT"
echo "   => curl -s https://$APPNAME.$TLS_INGRESS_APPADC_DOMAIN/debug/headers --cacert $TLS_FORTIDEMO_CERTPATH/$TLS_FORTIDEMO_CA_CERT"
echo
