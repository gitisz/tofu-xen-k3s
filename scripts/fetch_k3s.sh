#!/bin/bash
# Arguments: username, start_ip, alb_ip
USERNAME=$1
START_IP=$2
ALB_IP=$3

# Copy the k3s.yaml file to the local machine
scp -i .ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  $USERNAME@$START_IP:/k3s/local-k3s.yaml ~/.kube/config >/dev/null 2>&1

# Replace the 'server: https://127.0.0.1:6443' with the actual cluster IP
sed -i '' "s|server: https://127.0.0.1:6443|server: https://$ALB_IP:6443|g" ~/.kube/config >/dev/null 2>&1
