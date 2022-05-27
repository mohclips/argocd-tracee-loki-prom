#!/bin/bash

set -euxo pipefail

#
# install monitoring environment
#

# add the repos we need
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add giantswarm https://giantswarm.github.io/giantswarm-catalog
helm repo update

# mask exit code
kubectl create ns monitoring || true
# prometheus
helm upgrade --install prom prometheus-community/kube-prometheus-stack --namespace monitoring --values /vagrant/manifests/prom-values.yaml

# promtail
helm upgrade --install promtail grafana/promtail -f /vagrant/manifests/promtail-values.yaml --namespace monitoring

# loki
helm upgrade --install loki grafana/loki-distributed --namespace monitoring

# export vuln reports to prometheus
helm upgrade --install starboard-exporter --namespace starboard-system giantswarm/starboard-exporter

# tracee a replacement for falco
#sudo apt install linux-headers-$(uname -r)
#kubectl apply -f /vagrant/manifests/tracee-ds.yaml


echo "grafana login:  admin/prom-operator"

#
# Loki
#

# show all apps
# rate( ( {app=~ ".+"} [10m] ) ) 


