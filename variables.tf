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

variable "server_host_name_prefix" {
  default = "TOFU-SRVR"
}

variable "agent_host_name_prefix" {
  default = "TOFU-AGNT"
}

variable "server_node_count" {
  default = 3
}

variable "agent_node_count" {
  default = 3
}

variable "cluster_start_ip" {
  default = "10.10.10.4"
}

variable "server_alb_ip" {
  default = "10.10.10.3"
}


variable "agent_alb_primary_ip" {
  default = "10.10.10.30"
}

variable "agent_alb_additional_ips" {
  description = "List of IP addresses for agent ALB"
  type        = list(string)
  default     = [
    "10.10.10.31",
    "10.10.10.32",
    "10.10.10.33",
    "10.10.10.34",
    "10.10.10.35",
    "10.10.10.36",
    "10.10.10.37",
    "10.10.10.38",
    "10.10.10.39",
    "10.10.10.40"
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
