#!/usr/bin/bash

echo "# Install k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san 10.0.20.101 --tls-san 10.0.20.197" sh -
sudo k3s kubectl get nodes

rm -rf ~/.kube; mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/10.0.20.101/g' > ~/.kube/config
kubectl get ns

echo "# Install mettallb (DeepSeek)"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

echo "# Configure Metallb for Subnet Range: 10.0.20.150-10.0.20.190"
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dhcp-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.20.150-10.0.20.190
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advert
  namespace: metallb-system
spec:
  ipAddressPools:
  - dhcp-pool
EOF

sleep 5

echo "# Show Ingress IP Address"
kubectl get svc -n kube-system traefik
echo

echo "# Make k3s.yaml readable"
sudo chmod a+r /etc/rancher/k3s/k3s.yaml
echo
