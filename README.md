# tofu-xen-k3s
This repository contains Terraform (Tofu) to fully automate deploying a K3S Kubernetes cluster onto `XCP-NG`, with some additional benefits like `kube-vip` for server load-balancing and `metallb` for application load balancing.

## Getting Started
Create a `.env` file with the following variables:

    export TF_VAR_XOA_URL=wss://<your_xoa_hostname_or_ip>
    export TF_VAR_XOA_USER=<your_xoa_username>
    export TF_VAR_XOA_PASSWORD=<your_xoa_password>

Now source the `.env` file: `source .env`

### SSH Key Pair
Create an RSA SSH key pair: `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"` and save it to `.ssh/id_rsa` and `.ssh/id_rsa.pub` at the root of this cloned repository.

Change the permissions of the SSH key pair: `chmod 600 ~/.ssh/id_rsa`


    |-- .ssh
        |-- id_rsa
        |-- id_rsa.pub


### K3S Token
Create an folder called `.k3s` in the root of this cloned repository, then create a file in it called `k3s_token`. Add a your desired secret to this file. This token/secret will be used to join the K3S nodes to the cluster.


    |-- .k3s
        |-- k3s_token


### Terraform
Install Tofu:

    brew update
    brew install opentofu


Initialize the Terraform configuration: `tofu init`

Execute the Terraform plan: `tofu plan`.  This will output a list of resources that will be created.

## Deploying the K3S Cluster
This repository contains a Terraform configuration that will deploy a K3S cluster onto `XCP-NG` using `tofu`. The Terraform has variables that enable you to customize the deployment, for example:

    tofu plan -var="additional_server_vm_count=2" -var="additional_agent_vm_count=3"

This will show the plan for creating 3 server nodes for high availability and 3 agent nodes for your applications.

When the initial server is created, it will be configured with a static IP address, which can be defined during execution.

    tofu plan -var="additional_server_vm_count=2" -var="additional_agent_vm_count=3" -var="cluster_start_ip=192.168.1.10"

Each additional server node will be configured with a static IP address, which will be incremented by 1 for each additional server node.

_NOTE Agent nodes are configured with DHCP._

The automation installs `kube-vip` so that the cluster can be load balanced through a load balancer IP address, which can also be defined during execution.

    tofu plan -var="additional_server_vm_count=2" -var="additional_agent_vm_count=3" -var="load_balancer_ip=192.168.1.10"

The automation also installs `metallb` so that your applications can be load balanced through a load balancer IP address range, which can also be defined during execution.

    tofu plan -var="additional_server_vm_count=2" -var="additional_agent_vm_count=3" -var="load_balancer_ip=192.168.1.10" -var="load_balancer_ip_range=192.168.1.30-192.168.1.40"

