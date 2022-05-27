# -*- mode: ruby -*-
# vi: set ft=ruby :
#
#

# adapted from https://martin-devlin-26074.medium.com/kubernetes-cluster-with-vagrant-5c61901494c3

# Script for creating kvm (Kernel native) vm's for kubernetes
# Set to 1 controlplane and 2 workers by default with 2xCPU and 2GB RAM
# If you have enough memory available then they will run happier with 4GB

MEM=8192
K8S_VERSION = "1.24.0"

# Net work prefix in which a single digit is appended
# ex 192.168.121.1 will have a controlplane at 192.168.121.10 and workers starting from 192.168.121.11
# remember .1 is usually the router, so these go 10,11,12,13 etc.
#NETWORK_PREFIX = "192.168.15.1"
NETWORK_PREFIX = "172.30.5.3"

# assumes virtualbox has been installed
  # https://aquasecurity.github.io/tracee/dev/tutorials/setup-development-machine-with-vagrant/#switch-between-co-re-and-non-co-re-linux-distribution
  # config.vm.box = "ubuntu/focal64"       # Ubuntu 20.04 Focal Fossa (non CO-RE)
  # config.vm.box = "ubuntu/hirsute64"   # Ubuntu 21.04 Hirsute Hippo (CO-RE)
  # config.vm.box = "ubuntu/impish64"    # Ubuntu 21.10 Impish Indri (CO-RE)
IMAGE_NAME = "ubuntu/jammy64" # 22.04

# Can have 1-9 worker nodes
NUM_NODES = 1

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |vb|
  
    # change the network card hardware for better performance
    vb.customize ["modifyvm", :id, "--nictype1", "virtio" ]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio" ]

    # suggested fix for slow network performance
    # see https://github.com/mitchellh/vagrant/issues/1807
    #vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    #vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    # Enabling multiple cores in Vagrant/VirtualBox
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provider "virtualbox" do |v|
    v.memory = MEM
    v.cpus = 4
    # faster builds of workers
    v.linked_clone = true
  end

  config.vm.define "controlplane" do |controlplane|

    # faster builds - no rebuild of vbguest in kernel
      if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end
  
    controlplane.vm.box = IMAGE_NAME
    controlplane.vm.hostname = "controlplane"
    #controlplane.vm.synced_folder "./kubernetes", "/var/kubernetes"
    #controlplane.vm.network "private_network",
    controlplane.vm.network "public_network",
      ip: "#{NETWORK_PREFIX}0",
      hostname: true,
      bridge: "enp6s0"

    controlplane.vm.provision "shell", path: "init_scripts/common.sh"
    controlplane.vm.provision "shell", path: "init_scripts/controlplane.sh"
  end

  (1..NUM_NODES).each do |i|
    config.vm.define "worker-#{i}" do |node|

      if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
      end

      node.vm.box = IMAGE_NAME
      node.vm.hostname = "worker-#{i}"
      
      #node.vm.network "private_network",
      node.vm.network "public_network",
        ip: "#{NETWORK_PREFIX}#{i}",
        hostname: true,
        bridge: "enp6s0"


      node.vm.provision "shell", path: "init_scripts/common.sh"
      node.vm.provision "shell", path: "init_scripts/worker.sh"
    end
  end

#
# k8s environment setup
#
#  config.vm.define "worker-1" do |node|
#    # remote trivy systemd service on underlying docker (not k8s)
#    node.vm.provision "shell", path: "init_scripts/trivy-server.sh"
#  end
#
#  config.vm.define "controlplane" do |controlplane|
#    # cilium / argocd / starboard(trivy)
#    controlplane.vm.provision "shell", path: "init_scripts/cluster-init.sh"
#    # point starboard at remote trivy server
#    controlplane.vm.provision "shell", path: "init_scripts/trivy_client-server_patch.sh"
#    # prometheus / loki / grafana
#    controlplane.vm.provision "shell", path: "init_scripts/install-monitoring-environment.sh"
#  end

end
