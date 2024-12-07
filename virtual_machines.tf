

resource "xenorchestra_vm" "first_vm" {
  memory_max  = 8589934592  # 8 GB in bytes
  cpus        = 4
  name_label  = "${var.server_host_name_prefix}-0"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_first_vm.template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_first_vm.template

  network {
    network_id = data.xenorchestra_network.eth0.id
  }

  network {
    network_id = data.xenorchestra_network.vlan111.id
  }

  network {
    network_id = data.xenorchestra_network.eth1.id
  }

  disk {
    sr_id      = data.xenorchestra_sr.sr.id
    name_label = "${var.server_host_name_prefix}-SR-0"
    size       = 36829301760  # 36 GB in bytes
  }

  connection {
    type        = "ssh"
    user        = "administrator"
    host        = "${var.cluster_start_ip}"
    private_key = file(".ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for VM to be up...'",
      "while ! sudo test -f /var/lib/rancher/k3s/server/node-token; do echo 'Waiting for K3S token'; sleep 10; done",
      "while ! sudo test -f /k3s/local-k3s.yaml; do echo 'Waiting for K3S Kube Config'; sleep 10; done",
      "echo 'VM, K3S Token, and Kube Config are ready 🚀'"
    ]
  }

  provisioner "local-exec" {
    command = "bash ./scripts/fetch_k3s.sh ${var.XOA_USER} ${var.cluster_start_ip} ${var.cluster_alb_ip}"
  }

  tags = [
    "k3s",
    "k3s-server"
  ]

}


resource "xenorchestra_vm" "other_server_vms" {
  count       = var.server_vm_count - 1
  memory_max  = 8589934592  # 8 GB in bytes
  cpus        = 4
  name_label  = "${var.server_host_name_prefix}-${count.index + 1}"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_other_server_vms[count.index].template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_other_server_vms[count.index].template

  network {
    network_id = data.xenorchestra_network.eth0.id
  }

  network {
    network_id = data.xenorchestra_network.vlan111.id
  }

  network {
    network_id = data.xenorchestra_network.eth1.id
  }

  disk {
    sr_id      = data.xenorchestra_sr.sr.id
    name_label = "${var.server_host_name_prefix}-SR-${count.index + 1}"
    size       = 36829301760  # 36 GB in bytes
  }

  tags = [
    "k3s",
    "k3s-server"
  ]

  depends_on = [ xenorchestra_vm.first_vm ]

}


resource "xenorchestra_vm" "other_agent_vms" {
  count       = var.agent_vm_count
  memory_max  = 8589934592  # 8 GB in bytes
  cpus        = 4
  name_label  = "${var.agent_host_name_prefix}-${count.index}"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_other_agent_vms[count.index].template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_other_agent_vms[count.index].template

  network {
    network_id = data.xenorchestra_network.eth0.id
  }

  network {
    network_id = data.xenorchestra_network.vlan111.id
  }

  network {
    network_id = data.xenorchestra_network.eth1.id
  }

  disk {
    sr_id      = data.xenorchestra_sr.sr.id
    name_label = "${var.agent_host_name_prefix}-SR-${count.index + 1}"
    size       = 36829301760  # 36 GB in bytes
  }

  tags = [
    "k3s",
    "k3s-agent"
  ]

  depends_on = [ xenorchestra_vm.other_server_vms ]

}