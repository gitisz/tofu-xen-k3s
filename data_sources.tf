data "xenorchestra_pool" "pool" {
  name_label = "CLUSTER-0"
}

data "xenorchestra_hosts" "pool" {
  pool_id = data.xenorchestra_pool.pool.id

  sort_by = "name_label"
  sort_order = "asc"

}

data "xenorchestra_template" "vm_template" {
  name_label = "Debian Bookworm 12 - Cloud"
}

data "xenorchestra_sr" "sr" {
  name_label = "K3S-SR"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "eth0" {
  name_label = "eth0"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "vlan111" {
  name_label = "vlan111"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "eth1" {
  name_label = "eth1"
  pool_id = data.xenorchestra_pool.pool.id
}

data "external" "next_ip" {
  count = length(data.xenorchestra_hosts.pool.hosts) - 1
  program = ["python3", "./scripts/next_ip.py"]
  query = {
    start_ip  = var.cluster_start_ip
    increment = count.index + 1
  }
}

locals {
  cert_manager_issuer_environment = var.use_production_issuer ? "production" : "staging"
}
