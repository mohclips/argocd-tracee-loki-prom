# Test playground

- :ballot_box_with_check: Cilium CNI
- :ballot_box_with_check: ArgoCD 
- :ballot_box_with_check: Prometheus
- :ballot_box_with_check: Grafana
- :ballot_box_with_check: Loki
- :ballot_box_with_check: MetalLB
- :negative_squared_cross_mark: Tracee  (installed but no metrics yet - auditing is done)
- :negative_squared_cross_mark: Trivy  (requires docker to run)
- :negative_squared_cross_mark: k8s auditing (not yet done)

:construction: A work in progress :wrench:

---

# Summary

The idea is to link all these together and run tests (:skull: hacks :skull:) against the platform to see what is recorded.


# Requirements

- kubernetes 1.24.0 (latest at the time)
- containerd (not docker.io)
- Ubuntu 22.04 LTS  (required for BTF kernel and tracee)

# Notes

- tracee requires BTF in the kernel `ls -l /sys/kernel/btf/vmlinux`
- trivy requires docker (not containerd)

# Application method

- vagrant up
- vssh controlplane
- /vagrant/init-scripts/cluster-init.sh (install cilium)
- /vagrant/init_scripts/install-monitoring-environment.sh  (install prometheus, loki, grafana)
- /vagrant/init_scripts/metallb.sh  (LoadBalancer - this requires external DNS and changes to match local network)
- /vagrant/init_scripts/trivy_client-server_patch.sh
  
On the worker node
- vssh worker-1
- /vagrant/init_scripts/trivy-server.sh
(not yet working as no docker installed) - might wait for trivy to support containerd?

