#!/bin/bash

set -euxo pipefail

CONTROL_IP=$(hostname -i | sed -e 's/ /\n/g' | sort | uniq | head -n1) 
NODENAME=$(hostname -s)
POD_CIDR="10.1.0.0/16"

sudo kubeadm config images pull

sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

cp -i /etc/kubernetes/admin.conf /vagrant/configs/config

touch /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh

kubeadm token create --print-join-command > /vagrant/configs/join.sh

# at this point we are running as root

echo "+ copy config to vagrant user HOME on controlplane"
id -a
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

echo "+ vimrc setup"
cat <<EOF | sudo tee -a /etc/vim/vimrc

" k8s setup
set modeline
set modelines=5

set et sw=2 ts=2

color elflord
EOF

echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc

