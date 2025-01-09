variable "XOA_URL" {
  description = "The URL to Xen Orchestra."
}

variable "XOA_USER" {
  description = "The user with access to provision resources in Xen Orchestra."
  sensitive   = true
}

variable "XOA_PASSWORD" {
  description = "The password for the user with access to provision resources in Xen Orchestra."
  sensitive   = true
}

variable "INTERNAL_DOMAIN" {
  description = "The internal domain of your network."
  sensitive   = true
}

variable "INTERNAL_GATEWAY_IP" {
  description = "The internal gateway IP of your network."
  sensitive   = true
}

variable "INTERNAL_DNS_SERVERS" {
  description = "The internal DNS servers of your network."
  sensitive   = true
}


variable "SSH_ADMINISTRATOR_USERNAME" {
  description = "The username of the SSH administrator to enable logging into K3S nodes."
  sensitive   = true
}

variable "SSH_ADMINISTRATOR_PASSWORD" {
  description = "The password of the SSH administrator to enable logging into K3S nodes (optional, but must be generated using `openssl passwd -6`).v"
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_EMAIL" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_API_TOKEN" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_DNS_ZONE" {
  sensitive   = true
}

variable "CERT_MANAGER_LETSENCRYPT_EMAIL" {
  sensitive   = true
}

variable "TRAEFIK_DASHBOARD_AUTH" {
  sensitive   = true
}

variable "TRAEFIK_DASHBOARD_FQDN" {
  sensitive   = true
}

variable "KUBERNETES_DASHBOARD_FQDN" {
  sensitive   = true
}

variable "RANCHER_DASHBOARD_FQDN" {
  sensitive   = true
}

variable "RANCHER_BOOTSTRAP_PASSWORD" {
  sensitive = true
}

variable "server_host_name_prefix" {
  default = "TOFU-SRV"
}

variable "agent_host_name_prefix" {
  default = "TOFU-AGN"
}

variable "server_node_count" {
  default = 3
}

variable "server_node_cpu" {
  default = 8
}

variable "server_node_memory" {
  default = 17179869184
}

variable "agent_node_cpu" {
  default = 8
}

variable "agent_node_memory" {
  default = 17179869184
}

variable "agent_node_count" {
  default = 3
}

# agent nodes are assigned w/ dhcp
variable "server_start_ip" {
  default = "10.10.1.20"
}

variable "server_subnet_mask" {
  default = "21"
}

# kube-vpi
variable "server_alb_ip" {
  default = "10.10.1.30"
}

# metallb
variable "agent_alb_primary_ip" {
  default = "10.10.1.40"
}

variable "agent_alb_additional_ips" {
  description = "List of IP addresses for agent ALB"
  type        = list(string)
  default     = [
    "10.10.1.41",
    "10.10.1.42",
    "10.10.1.43"
  ]
}

variable "with_cert_manager" {
  default = "false"
}

variable "use_production_issuer" {
  description = "Use production issuer if true, otherwise use the staging issuer."
  type        = bool
  default     = false
}

variable "with_traefik" {
  default = "false"
}

variable "with_k8s_dashboard" {
  default = "false"
}

variable "with_rancher_dashboard" {
  default = "false"
}

variable "rancher_load_balancer_ip" {
  default = "10.10.1.41"
}
