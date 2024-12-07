# tofu-xen-k3s
This repository contains Terraform (Tofu) to fully automate deploying a K3S Kubernetes cluster onto `XCP-NG`, with some additional benefits like `kube-vip` for server load-balancing and `metallb` for application load balancing.

## Getting Started
Create a `.env` file with the following variables:

    export TF_VAR_XOA_URL=wss://<your_xoa_hostname_or_ip>
    export TF_VAR_XOA_USER=<your_xoa_username>
    export TF_VAR_XOA_PASSWORD=<your_xoa_password>

Now source the `.env` file: `source .env`

Create an RSA SSH key pair: `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"` and save it to `.ssh/id_rsa` and `.ssh/id_rsa.pub` at the root of this cloned repository.

Change the permissions of the SSH key pair: `chmod 600 ~/.ssh/id_rsa`

Create an empty file in `.k3s` called `k3s_token` and save it at the root of this cloned repository. Add a your desired secret to this file. This token/secret will be used to join the K3S nodes to the cluster.

Install Tofu:

    brew update
    brew install opentofu



Initialize the Terraform configuration: `tofu init`

Execute the Terraform plan: `tofu plan`