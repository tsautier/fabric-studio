#!/usr/bin/bash

export NAMESPACE=nginx-ingress-tls

# Deploy a Test Service:
kubectl create ns $NAMESPACE

echo "# Deploy NGINX"
cat <<EOF | kubectl -n $NAMESPACE  apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

echo "# Expose NGINX via ClusterIP Service"
cat <<EOF | kubectl -n $NAMESPACE apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF

echo "# Create TLS Certificate secret"
kubectl create secret tls wildcard-tls-cert \
  --namespace $NAMESPACE \
  --cert=certificates/apps_tkg_fortidemo.cer \
  --key=certificates/apps_tkg_fortidemo.key

echo "# Create Ingress Resource for NGINX"
cat <<EOF | kubectl -n $NAMESPACE apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure  # Use HTTPS entrypoint
    traefik.ingress.kubernetes.io/router.tls: "true"             # Enable TLS
spec:
  ingressClassName: traefik
  tls:
  - secretName: wildcard-tls-cert   # Secret containing the TLS certificate
    hosts:
    - "*.apps.tkg.fortidemo.ch"     # Wildcard domain covered by the certificate
  rules:
  - host: nginx.apps.tkg.fortidemo.ch   # Your specific hostname
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF
