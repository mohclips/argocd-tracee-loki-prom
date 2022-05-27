#!/bin/bash

set -euxo pipefail

STARBOARD_VERSION=v0.15.4

install_cilium() {
  echo "################## install cilium"
  # https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
  if [[ ! -e /usr/local/bin/cilium ]] ; then
    curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
    rm cilium-linux-amd64.tar.gz{,.sha256sum}
  else
    echo "already installed"
  fi
  #cilium install --cluster-name "demo-cluster" --cluster-id 1
  id -a
  cilium install

  # could need to be longer depending on hardware resources available
  WAIT_SECS=60
  echo "Waiting $WAIT_SECS..."
  sleep $WAIT_SECS

  cilium status --wait

  #echo "note that this may well fail - but it doesnt mean it actually did fully!!!"
  # i find that "applying network policies: policies were not applied on all Cilium nodes in time: command terminated with exit code 1" happens a lot!
  #cilium connectivity test -v

  #echo "!!! SUCCESS !!!"

  curl -sk https://localhost:6443/healthz?verbose | grep -v "ok$"
  curl -sk https://localhost:6443/livez?verbose | grep -v "ok$"
  curl -sk https://localhost:6443/readyz?verbose | grep -v "ok$"
}

#
# Main
#
id -a

mkdir $HOME/.kube || true
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

if [[ ! -r /home/vagrant/.kube/config ]] ; then
  sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  sudo chown -R vagrant:vagrant /home/vagrant/.kube/
else

  echo "kubeconfig found"
fi

echo "+ install cilium"
CNI=$(sudo find /etc/cni/net.d/ -maxdepth 0 -empty -exec echo empty \;)
if [[ $CNI == "empty" ]] ; then
  install_cilium
else
  echo "already installed"
fi

echo "+ display Cilium health"
kubectl -n kube-system get pods -l k8s-app=cilium -owide

CILIUM_PODS=$(kubectl -n kube-system get pods -l k8s-app=cilium -oname)
for CP in $CILIUM_PODS ; do
  kubectl -n kube-system exec $CP -- cilium status | grep --color 'Controller Status.*\|$' 
  echo ""
done

# a visual check seems to be better here
kubectl get nodes -o wide
kubectl get pods -A

#k get cs - Warning: v1 ComponentStatus is deprecated in v1.19+
# manual check - look for warnings (not the 'ok')
curl -sk https://localhost:6443/healthz?verbose | grep -v "ok$"
curl -sk https://localhost:6443/livez?verbose | grep -v "ok$"
curl -sk https://localhost:6443/readyz?verbose | grep -v "ok$"


echo "Cluster init - done"
exit 0

