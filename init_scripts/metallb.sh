#!/bin/bash

set -euxo pipefail

# if IPVS mode in kube-proxy see https://metallb.universe.tf/installation/#preparation

helm repo add metallb https://metallb.github.io/metallb

# see https://metallb.universe.tf/usage/#requesting-specific-ips
# if you want specific IPs for services
# create lots of address-pools with your IPs in each and
# then in your service define annotations: metallb.universe.tf/address-pool: my-new-pool

cat<<EOF | tee /tmp/metallb.values.yaml
configInline:
  address-pools:
   - name: default
     protocol: layer2
     addresses:
     - 172.30.5.23-172.30.5.28
   - addresses:
     - 172.30.5.29/32
     name: nginx-ingress
     protocol: layer2

EOF

kubectl create ns metallb | true

helm install -n metallb metallb metallb/metallb -f /tmp/metallb.values.yaml

cat<<
+ wait for metallb-controller pod to start - then check argocd server service for an external IP
  kubectl get svc -n argocd argocd-server
EOF

echo "sleep 120"
sleep 120

cat<<EOF
The following are setup in the local DNS and is required for ingress host matching

;;
k8s-ingest              A       172.30.5.29
argo.k8s-ingest         CNAME   k8s-ingest
graf.k8s-ingest         CNAME   k8s-ingest
prom.k8s-ingest         CNAME   k8s-ingest
alert.k8s-ingest        CNAME   k8s-ingest

EOF

#
# install nginx-ingress
#
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml

# this gives it a remote IP .29 - a single IP for ingress "nginx-ingress"
kubectl -n ingress-nginx patch svc ingress-nginx-controller -p '{"spec": {"type": "LoadBalancer"},"metadata": { "annotations": { "metallb.universe.tf/address-pool": "nginx-ingress" }}}'

# Patch required for ArgoCD
# see https://stackoverflow.com/a/70168709
kubectl -n ingress-nginx patch deployment ingress-nginx-controller \
    --type=json \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'

# apply argocd ingress (with SSL pass-thru)
kubectl apply -f /vagrant/manifests/argocd-ingress.yaml

# apply monitoring ingresses
kubectl apply -f /vagrant/manifests/monitoring-ingress.yaml




