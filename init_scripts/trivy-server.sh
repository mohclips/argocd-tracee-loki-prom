#!/bin/bash

sudo useradd -G docker -c "trivy service" -m -d /home/trivy trivy

cd /home/trivy/

# download binary
if [[ ! -e /home/trivy/trivy ]]  ; then
	sudo wget https://github.com/aquasecurity/trivy/releases/download/v0.28.0/trivy_0.28.0_Linux-64bit.tar.gz
	sudo tar xvzf trivy_0.28.0_Linux-64bit.tar.gz
else
	echo "Already downloaded"
fi

cat<<EOF | sudo tee /etc/systemd/system/trivy.service
[Unit]
Description=trivy service

# After networking because we need that
After=network.target

[Service]

# Simple services don't do any forking / background nonsence
Type=simple

# User with which to run the service
User=trivy

# Any setup we need to do, specifying the shell because otherwise who knows what's up
ExecStartPre=/bin/bash -c 'echo "hello world"'

# Set the working directory for the application
WorkingDirectory=/home/trivy

# Command to run the application
ExecStart=/home/trivy/trivy --debug server --listen 0.0.0.0:8888

# Restart policy, only on failure
Restart=on-failure

[Install]
# Start the service before we get to multi-user mode
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable trivy
sudo systemctl start trivy
echo "wait 5"
sleep 5
sudo systemctl status trivy
