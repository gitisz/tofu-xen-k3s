# tofu-xen-k3s
This repository contains Terraform ([OpenTofu](https://opentofu.org/docs/)) to fully automate deploying a [K3S](https://docs.k3s.io/) Kubernetes cluster on a Xen cluster ([XCP-NG](https://docs.xcp-ng.org/)), with some additional benefits like:

 - [`kube-vip`](https://kube-vip.io/docs/usage/k3s/) for server load-balancing
 - [`metallb`](https://metallb.io/) for application load balancing
 - [`cert-manager`](https://cert-manager.io/docs/) for SSL/TLS certificates
 - [`traefik`](https://doc.traefik.io/traefik/) for ingress routing
 - [`kubernetes-dashboard`](https://github.com/kubernetes/dashboard/) for cluster management
 - [`rancher`](https://ranchermanager.docs.rancher.com/) for cluster management

The Terraform relies heavily on [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) which is used to configure the VMs with all this goodness.

## Getting Started
Before proceeding, you will need to update and source your `.env` file. You can find a template in this project in the root folder with a file name of `dot_env`. Copy this file to `.env` and update the values.

The following environment variables are required:

 - **export TF_VAR_XOA_URL=<xoa_url>** # The websocket url to your Xen Orchestra appliance, e.g. "wss://10.10.0.20"
 - **export TF_VAR_XOA_USER=<xoa_user>** # The username of the Xen Orchestra administrator.
 - **export TF_VAR_XOA_PASSWORD=<xoa_password>** # The password of the Xen Orchestra administrator.
 - **export TF_VAR_INTERNAL_GATEWAY_IP=<internal_gateway_ip>** # The internal gateway IP address of your network.
 - **export TF_VAR_INTERNAL_DNS_SERVERS=<internal_dns_servers>** # The internal DNS servers of your network (e.g. "10.1.0.11,10.1.0.11").
 - **export TF_VAR_INTERNAL_DOMAIN=<internal_domain>** # The internal domain of your network.
 - **export TF_VAR_SSH_ADMINISTRATOR_USERNAME=<ssh_administrator_username>** # The username of the SSH administrator to enable logging into K3S nodes.
 - **export TF_VAR_SSH_ADMINISTRATOR_PASSWORD=<ssh_administrator_password>** # The password of the SSH administrator to enable logging into K3S nodes (optional, but must be generated using `openssl passwd -6`).

Now source the `.env` file: `source .env`

### SSH Key Pair
Create an RSA SSH key pair: `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"` and save it to `.ssh/id_rsa` and `.ssh/id_rsa.pub` at the root of this cloned repository.

Change the permissions of the SSH key pair: `chmod 600 ~/.ssh/id_rsa`

    |-- .ssh
        |-- id_rsa
        |-- id_rsa.pub


### K3S Token
Create a folder called `.k3s` in the root of this cloned repository, then create a file in it called `k3s_token`. Add your desired secret to this file. This token/secret will be used to join the K3S nodes to the cluster.


    |-- .k3s
        |-- k3s_token

### Cloud Image
For the Xen VMs to be created, you will need a cloud image.

This guide started by referring to a blog at [mikansoro.org](https://mikansoro.org/blog/debian-cloud-init-xen-orchestra/), however that guide didn't fully work out. Instead, this guide uses a Debian 12 Bookwork cloud image, and uses Terraform to take care of installing the `xe-guest-utilities`.

Therefore, you will need to download the Debian 12 Bookwork cloud image from the [Debian website](https://cdimage.debian.org/images/cloud/bookworm/) and create a Xen Orchestra Template from it (no need to create a new VM from the image, boot it, install guest-utilities, and then create a template from it), instead, just convert the `qcow2` image to a `.vmdk` disk, then create a template from the image with a name of `Debian Bookworm 12 - Cloud`.

**Example**:
 1. `qemu-img convert -f qcow2 -O vmdk debian-12-generic-amd64-20241125-1942.qcow2 debian-12-generic-amd64-20241125-1942.vmdk`
 2. Import the template into Xen Orchestra

<img src="docs/vmdk-import-cloud-image-1.png" width="400"  alt="vmdk-import-cloud-image-1">

 3. Create a new VM based on an existing template `Debian Bookworm 12`
 4. Name the VM `Debian Bookworm 12 - Cloud`
 5. Select Install Settings > PXE boot
 6. Remove any interfaces from the VM
 7. Remove any disks from the VM
 7. Uncheck Advanced > Boot VM after creation

<img src="docs/vmdk-import-cloud-image-2.png" width="400"  alt="vmdk-import-cloud-image-2">
<img src="docs/vmdk-import-cloud-image-3.png" width="400"  alt="vmdk-import-cloud-image-3">

 8. Click Create

 9. From the new VM, click Disks > Attach disk, and attach the `.vmdk` file you created in step 1.

<img src="docs/vmdk-import-cloud-image-4.png" width="400"  alt="vmdk-import-cloud-image-4">

 10. From Advanced, change to boot order to Hard-Drive, click Save
 11. Click Convert to Template

<img src="docs/vmdk-import-cloud-image-5.png" width="400"  alt="vmdk-import-cloud-image-5">

### Terraform
Install [OpenTofu](https://opentofu.org/docs/):

    brew update
    brew install opentofu

After cloning this repository and at the root of the project, initialize the Terraform configuration: `tofu init`.

Execute the Terraform plan: `tofu plan`.

This will output a list of resources for your review prior to committing to creating any resources.

## Deploying the K3S Cluster
This repository contains a Terraform configuration that will deploy a K3S cluster onto `XCP-NG` using `tofu`.

### Planning the Deployment
First, you should `tofu plan` your deployment and review the generated output to ensure that the deployment will meet your requirements.


The Terraform has variables that enable you to customize the deployment, for example:

```
tofu plan -var="agent_node_count=3"
```

The output will show the plan for creating server nodes (based on your XCP-NC pool host count, for high availability) and 3 agent nodes for your applications.

When you are ready, execute `tofu apply -var="agent_node_count=3"`. When the first server node is actually created, it will be configured with a static IP address (also configurable as a variable).

```
tofu apply -var="agent_node_count=3" -var="server_start_ip=192.168.1.10"
```

Using affinity, a server node will get created for each host within the XCP-NG XOA pool.

Each additional server node will be configured with a static IP address, which will be incremented by 1 for each additional server node. Example, if the first server node is configured with a static IP address of `192.168.1.10`, the second server node will be configured with a static IP address of `192.168.1.11`, etc.

_NOTE Agent nodes are configured with DHCP, and they are also dispersed through affinity_

### Kube-VIP
So that the cluster can be managed through a single load balancer IP address, the automation installs `kube-vip`. Be sure to also specify the IP address of the load balancer which will be used for the `kube-vip` VIP.

```
tofu plan -var="agent_node_count=3" -var="server_alb_ip=192.168.1.10"
```

### Metallb
The automation also installs [`metallb`](https://metallb.io/) so that your applications can be load balanced through a load balancer IP address range, which can also be defined during execution.

```
tofu plan -var="agent_node_count=3" -var="server_alb_ip=192.168.1.10" -var="agent_alb_additional_ips=192.168.1.30-192.168.1.40"
```

### Executing the Deployment
If the `tofu plan` looks good, you can execute it with `tofu apply`. Here is an example of executing the deployment with the variables defined above:

```
tofu apply -var="agent_node_count=3" \
  -var="load_balancer_ip=192.168.1.10" \
  -var="server_start_ip=192.168.1.11" \
  -var="agent_alb_primary_ip=192.168.1.30"
  -var='agent_alb_additional_ips=["192.168.1.31","192.168.1.31","192.168.1.32","192.168.1.33","192.168.1.34","192.168.1.35","192.168.1.36","192.168.1.37","192.168.1.38","192.168.1.39","192.168.1.40"]'
```

Unless you have provided your own names, you should expect the following resources to be created in XOA:

**K3S Cluster**
 - TOFU-SRVR-0
 - TOFU_SRVR-1
 - TOFU_SRVR-2

**K3S Agent Nodes**
 - TOFU_AGNT-0
 - TOFU_AGNT-1
 - TOFU_AGNT-2

During provisioning, the first VM `TOFU-SRVR-0` will be configured with a static IP address, and when the IP is assigned, the automation will then begin to check for the readiness of the k3s cluster.

When the cluster is ready, the automation will download the `kube-config` file locally for you. This makes it convenient for you to execute `kubectl` commands from your local machine against the cluster.

Also, after the k3s cluster is ready, the automation will then install `kube-vip` and `metallb` on the cluster, and then configure the load balancer IP address and load balancer IP range.

Finally, the automation will create the additional server nodes and agent nodes, and then join them to the k3s cluster.

## With Cert-Manager
You have an additional option to install [`cert-manager`](https://cert-manager.io/docs/) on the cluster.

**IMPORTANT**: _This option should not be used unless you have first thoroughly tested certificate issuance with `cert-manager` in your cluster using the `staging` issuer. Once tested & validated, the cluster can be destroyed and recreated with cert-manager` through the provided automation._

Before proceeding, you will need to update and source your `.env` file. The following environment variables are required:

 - **export TF_VAR_CERT_MANAGER_CLOUDFLARE_EMAIL=<cloudflare_email>** # associated with the Cloudflare account.
 - **export TF_VAR_CERT_MANAGER_CLOUDFLARE_API_TOKEN=<cloudflare_api_token>**: # retrieved from you Cloudflare account.
 - **export TF_VAR_CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX=<cloudflare_secret_name_prefix>** # to be used for the Cloudflare DNS secret, e.g. A value of `my-domain-com` will result in a K3S secret `my-domain-com-production-tls` for appending to other app installations.
 - **export TF_VAR_CERT_MANAGER_CLOUDFLARE_DNS_ZONE=<cert_manager_cloudflare_dns_zone>** # e.g. `my-domain.com`
 - **export TF_VAR_CERT_MANAGER_LETSENCRYPT_EMAIL=<cert_manager_letsencrypt_email>** # to be used for the Let's Encrypt email address.

When you execute the Terraform `apply`, you can provide the `with_cert_manager=true` option to automatically install `cert-manager` on the cluster.

```
tofu plan -var="with_cert_manager=true"
```

Or:

```
tofu apply -auto-approve -var="with_cert_manager=true"
```

**IMPORTANT**: _This option will install the `staging` issuer by default, allowing you to verify and ensure Let's Encrypt returns a valid staging certificate.  If using a misconfigured `production` certificate, Let's Encrypt can block DNS challenges preventing SSL/TLS renewal for up to 7 days._

If you are ready to install the K3S cluster using a `production` certificate, you can provide the `with_cert_manager=true` option, as well the `use_production_issuer=true` option.

**Example**:

```
tofu apply -var="with_cert_manager=true" -var="use_production_issuer=true"
```

## With Traefik
You have an additional option to install [`Traefik`](https://doc.traefik.io/traefik/) on the cluster.

This capability enables you to expose your K3S apps to your external network's subnet.

Additionally, when paired with [cert-manager](https://cert-manager.io/docs/), you can configure `IngressRoute`(s) with Traefik to expose a trusted certificate issued by Let's Encrypt.

**NOTE**: _The Traefik configuration requires at least 1 agent node._

### Automatically Configure Traefik
Before proceeding, you will need to update and source your `.env` file. The following environment variables are required:

 - **export TF_VAR_TRAEFIK_DASHBOARD_AUTH=<traefik_dashboard_auth>**: # a base64 encoded username & password to enable the Traefik dashboard to accept basic authentication.
 - **export TF_VAR_TRAEFIK_DASHBOARD_FQDN=<traefik_dashboard_fqdn>**: # the fully qualified domain name to expose the Traefik dashboard.
 - **export TF_VAR_CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX=<cert_manager_cloudflare_dns_secret_name_prefix>** # `<cloudflare-dns-secret-name-prefix>` to be used for the Cloudflare DNS secret, e.g. A value of `my-domain-com` will result in a K3S secret `traefik-my-domain-com-staging-tls`.

When you execute the Terraform `apply`, you can provide the `with_traefik=true` option to automatically install `Traefik` onto the cluster.

```
tofu plan -var="with_cert_manager=true" -var="with_traefik=true"
```

Or:

```
tofu apply -auto-approve -var="with_cert_manager=true" -var="with_traefik=true"
```

**NOTE**: _When installing Traefik and Cert-Manager, an additional Cloudflare certificate and secret will be installed in the `traefik` namespace. Once installed you will be able to access the Traefik dashboard at https://traefik.my-domain.com/ using a certificate generated by Let's Encrypt._

<img width="800" alt="image" src="https://github.com/user-attachments/assets/9552f541-dc2b-440b-9b7c-80b58e2b6db0" />

## With Kubernetes Dashboard
You have an additional option to install the [`kubernetes-dashboard`](https://github.com/kubernetes/dashboard/) on the cluster.

This capability enables you manage your cluster using a web-based dashboard.

Additionally, when paired with [cert-manager](https://cert-manager.io/docs/), you can configure `IngressRoute`(s) with Traefik to expose a trusted certificate issued by Let's Encrypt.

**NOTE**: _The kubernetes-dashboard configuration requires Traefik and Cert-Manager to also be installed._

### Automatically Configure Kubernetes Dashboard
Before proceeding, you will need to update and source your `.env` file. The following environment variables are required:

 - **export TF_VAR_KUBERNETES_DASHBOARD_FQDN=<kubernetes_dashboard_fqdn>**: # the fully qualified domain name to expose the kubernetes dashboard.

When you execute the Terraform `apply`, you can provide the `with_k8s_dashboard=true` option to automatically install `kubernetes-dashboard` onto the cluster.

```
tofu plan -var="with_cert_manager=true" -var="with_traefik=true" -var="with_traefik=true" -var="with_k8s_dashboard=true"
```

Or:

```
tofu apply -auto-approve -var="with_cert_manager=true" -var="with_traefik=true" -var="with_traefik=true" -var="with_k8s_dashboard=true"
```

Once the cluster has been installed you will be able to access the kubernetes dashboard at https://kubernetes-dashboard.my-domain.com/ using a certificate generated by Let's Encrypt.

You will be prompted to login to the kubernetes dashboard using a token which much be generated by running the following command:

```
kubectl -n kubernetes-dashboard create token admin-user
```

Copy the token and paste it into the kubernetes dashboard login form.

## With Rancher
You have an additional option to install the [`rancher`](https://ranchermanager.docs.rancher.com/) on the cluster.

Additionally, when paired with [cert-manager](https://cert-manager.io/docs/), you can configure `IngressRoute`(s) with Traefik to expose a trusted certificate issued by Let's Encrypt.

**NOTE**: _The rancher configuration requires Traefik and Cert-Manager to also be installed._

### Automatically Configure Rancher Dashboard
Before proceeding, you will need to update and source your `.env` file. The following environment variables are required:

 - **export TF_VAR_RANCHER_DASHBOARD_FQDN=<rancher_dashboard_fqdn>**: # the fully qualified domain name to expose the rancher dashboard.
 - **export TF_VAR_RANCHER_BOOTSTRAP_PASSWORD=<rancher_bootstrap_password>**: # the password to use to bootstrap the rancher server (later used to log into the dashboard).


When you execute the Terraform `apply`, you can provide the `with_rancher_dashboard=true` option to automatically install `rancher-dashboard` onto the cluster.

```
tofu plan -var="with_cert_manager=true" -var="with_traefik=true" -var="with_rancher_dashboard=true"
```

Or:

```
tofu apply -auto-approve -var="with_cert_manager=true" -var="with_traefik=true" -var="with_rancher_dashboard=true"
```


## Inspirations
This Terraform configuration was inspired by the following sources:

 - https://mikansoro.org/blog/debian-cloud-init-xen-orchestra/
 - https://technotim.live/posts/k3s-etcd-ansible/