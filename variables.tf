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

variable "TRAEFIK_DASHBOARD_HOST" {
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

variable "agent_alb_ip_range" {
  default = "10.10.10.30-10.10.10.40"
}

variable "agent_alb_primary_ip" {
  default = "10.10.10.30"
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

