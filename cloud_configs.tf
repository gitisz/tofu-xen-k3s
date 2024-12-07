
resource "xenorchestra_cloud_config" "cloud_config_first_vm" {
  name      = "Hosted VM Cloud-Init: User-Data"
  template  = templatefile(
    "./cloud-init/cloud-init-autoinstall-first-vm.tftpl",
    {
      count      = 0,
      vm_type   = "first_vm",
      host_name_prefix  = var.server_host_name_prefix,
      ssh_public_key = file(".ssh/id_rsa_pub"),
      k3s_token  = file(".k3s/k3s_token"),
      cluster_alb_ip = var.cluster_alb_ip,
      cluster_start_ip =  "${var.cluster_start_ip}",
      metallb_yaml      = indent(6, templatefile("./metallb/metallb-address-pool.yaml", {
        metallb_ip_range = var.metallb-ip-range
      }))
    }
  )
}

resource "xenorchestra_cloud_config" "cloud_network_config_first_vm" {
  name      = "Hosted VM Cloud-Init: Network"
  template  = templatefile(
    "./cloud-init/cloud-init-networks-static.tftpl",
    {
      ip_address = "${var.cluster_start_ip}"
    }
  )
}

resource "xenorchestra_cloud_config" "cloud_config_other_server_vms" {
  count     = var.additional_server_vm_count
  name      = "Hosted VM Cloud-Init: User-Data"
  template  = templatefile(
    "./cloud-init/cloud-init-autoinstall-other-server-vms.tftpl",
    {
      count      = count.index + 1,
      vm_type   = "server_vm",
      host_name_prefix  = var.server_host_name_prefix,
      ssh_public_key = file(".ssh/id_rsa_pub"),
      k3s_token  = file(".k3s/k3s_token"),
      cluster_alb_ip = var.cluster_alb_ip,
      cluster_start_ip =  "${var.cluster_start_ip}"
    }
  )
}

resource "xenorchestra_cloud_config" "cloud_network_config_other_server_vms" {
  count     = var.additional_server_vm_count
  name      = "Hosted VM Cloud-Init: Network"
  template  = templatefile(
    "./cloud-init/cloud-init-networks-static.tftpl",
    {
      ip_address = data.external.next_ip[count.index].result.next_ip
    }
  )
}


resource "xenorchestra_cloud_config" "cloud_config_other_agent_vms" {
  count     = var.additional_agent_vm_count
  name      = "Hosted VM Cloud-Init: User-Data"
  template  = templatefile(
    "./cloud-init/cloud-init-autoinstall-other-agent-vms.tftpl",
    {
      count               = count.index + 1,
      vm_type             = "agent_vm",
      host_name_prefix    = var.agent_host_name_prefix,
      ssh_public_key      = file(".ssh/id_rsa_pub"),
      k3s_token           = file(".k3s/k3s_token"),
      cluster_alb_ip      = var.cluster_alb_ip,
      cluster_start_ip    = "${var.cluster_start_ip}"
    }
  )
}


resource "xenorchestra_cloud_config" "cloud_network_config_other_agent_vms" {
  count     = var.additional_agent_vm_count
  name      = "Hosted VM Cloud-Init: Network"
  template  = templatefile(
    "./cloud-init/cloud-init-networks-dhcp.tftpl",
    {
    }
  )
}
