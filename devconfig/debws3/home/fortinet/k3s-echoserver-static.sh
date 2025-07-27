#!/bin/bash

# Deploy a Test Service:
kubectl create ns echoserver-static

kubectl -n echoserver-static create deployment echoserver --port=8080 --image=k8s.gcr.io/echoserver:1.10
kubectl -n echoserver-static expose deployment echoserver --port=8080 --type=LoadBalancer

sleep 10

ip=$(kubectl -n echoserver-static get svc echoserver -o json | jq -r '.status.loadBalancer.ingress[].ip')

echo "curl http://$ip"
