#!/bin/bash

set -euxo pipefail

MEM=8192
# 1.24.0 uses containerd, thus you need to use an earlier version until trivy/starboard catches up!
#K8S_VERSION="1.23.6"
K8S_VERSION="1.24.0"

# Net work prefix in which a single digit is appended
# ex 192.168.121.1 will have a controlplane at 192.168.121.10 and workers starting from 192.168.121.11
# remember .1 is usually the router, so these go 10,11,12,13 etc.
NETWORK_PREFIX="192.168.15.1"

# assumes virtualbox has been installed
#IMAGE_NAME="ubuntu/bionic64"

# Can have 1-9 worker nodes
NUM_NODES=1

HOST_IP=$(hostname -i | sed -e 's/ /\n/g' | sort | uniq)

sudo timedatectl set-timezone Europe/London

# see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

echo "Make sure BTF is in the kernel"
ls -l /sys/kernel/btf/vmlinux

export DEBIAN_FRONTEND=noninteractive
echo Number of worker nodes: ${NUM_NODES}
NODE=1
while [ ${NODE} -le ${NUM_NODES} ]; do
  sudo echo "${HOST_IP} worker-${NODE} worker-${NODE}.local" >> /etc/hosts
  NODE=$((NODE+1))
done


#
# fix dns - by removing systemd resolvd
#

sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved
sudo rm /etc/resolv.conf
cat<<EOF | sudo tee /etc/resolv.conf
# provisioned by vagrant init scripts
nameserver 172.30.5.253
options edns0 trust-ad
search homelan.local
EOF
sudo chmod 644 /etc/resolv.conf

ping -c 4 one.one.one.one

dig one.one.one.one




# we use docker.io to be able to use trivy (as trivy only supports docker presently)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt upgrade -y
# docker.io - removed
sudo apt install -y apt-transport-https ca-certificates curl lsb-release nfs-common jq strace binutils containerd
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=${K8S_VERSION}-00 kubectl=${K8S_VERSION}-00 kubeadm=${K8S_VERSION}-00
sudo apt-mark hold kubelet kubeadm kubectl

#
# kernel config
#
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/90-k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
# see https://github.com/cilium/cilium/issues/10645
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.lxc*.rp_filter = 0
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# containerd setup the config file
mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml
sudo crictl config --set runtime-endpoint=unix:///var/run/containerd/containerd.sock
# set runtime to runc
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
# allow vagrant to run crictl
#sudo chgrp vagrant /var/run/containerd/containerd.sock  # a restart of the containerd service resets this!

#cat <<EOF | sudo tee /etc/docker/daemon.json
#{
#  "exec-opts": ["native.cgroupdriver=systemd"],
#  "log-driver": "json-file",
#  "log-opts": {
#    "max-size": "100m"
#  },
#  "storage-driver": "overlay2",
#  "debug": false
#}
#EOF


#sudo systemctl enable docker
#sudo systemctl daemon-reload
#sudo systemctl restart docker

#
# allow vagrant user access to docker and containerd
#
#sudo usermod -G docker vagrant


# using Tracee now

# Install falco - https://falco.org/docs/getting-started/installation/
#curl -s https://falco.org/repo/falcosecurity-3672BA8F.asc | apt-key add -
#echo "deb https://download.falco.org/packages/deb stable main" | tee /etc/apt/sources.list.d/falcosecurity.list
#apt-get update -y
#apt-get -y install linux-headers-$(uname -r) falco
#sudo systemctl enable falco
#sudo systemctl daemon-reload
#sudo systemctl restart falco

