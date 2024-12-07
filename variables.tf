variable "XOA_URL" {
  description = "The URL to Xen Orchestra."
}

variable "XOA_USER" {
  description = "The user with access to provision resources in Xen Orchestra."
}

variable "XOA_PASSWORD" {
  description = "The password for the user with access to provision resources in Xen Orchestra."
}

variable "server_host_name_prefix" {
  default = "TOFU-SRVR"
}

variable "agent_host_name_prefix" {
  default = "TOFU-AGNT"
}

variable "additional_server_vm_count" {
  default = 2
}

variable "additional_agent_vm_count" {
  default = 3
}

variable "cluster_start_ip" {
  default = "10.10.10.4"
}

variable "cluster_alb_ip" {
  default = "10.10.10.3"
}


variable "metallb-ip-range" {
  default = "10.10.10.30-10.10.10.40"
}
