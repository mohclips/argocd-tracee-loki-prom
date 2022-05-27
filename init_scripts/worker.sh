#!/bin/bash
  
set -euxo pipefail

echo "worker script"

/bin/bash /vagrant/configs/join.sh -v

