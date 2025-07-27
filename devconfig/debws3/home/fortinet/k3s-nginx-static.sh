#!/usr/bin/bash

# Deploy a Test Service:
kubectl create ns nginx-static
kubectl -n nginx-static create deployment nginx --image=nginx
kubectl -n nginx-static expose deployment nginx --port=80 --type=LoadBalancer

sleep 10

ip=$(kubectl -n nginx-static get svc nginx -o json | jq -r '.status.loadBalancer.ingress[].ip')

echo "curl http://$ip"
