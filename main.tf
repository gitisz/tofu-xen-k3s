#  (       (              (         )    ) (         (
#  )\ )    )\ )           )\ )   ( /( ( /( )\ )      )\ )
# (()/((  (()/((   (  (  (()/(   )\()))\()|()/(  (  (()/(
#  /(_))\  /(_))\  )\ )\  /(_)) ((_)\((_)\ /(_)) )\  /(_))
# (_))((_)(_))((_)((_|(_)(_))    _((_) ((_|_))_ ((_)(_))
# / __| __| _ \ \ / /| __| _ \  | \| |/ _ \|   \| __/ __|
# \__ \ _||   /\ V / | _||   /  | .` | (_) | |) | _|\__ \
# |___/___|_|_\ \_/  |___|_|_\  |_|\_|\___/|___/|___|___/

resource "xenorchestra_vm" "server_first_node" {
  memory_max  = var.server_node_memory
  cpus        = var.server_node_cpu
  name_label  = "${var.server_host_name_prefix}-0"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_server_first_node.template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_server_first_node.template
  affinity_host = data.xenorchestra_hosts.pool.hosts[0].id
  tags = [
    "k3s",
    "k3s-server"
  ]

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
    command = "bash ./scripts/fetch_k3s.sh ${var.XOA_USER} ${var.cluster_start_ip} ${var.server_alb_ip}"
  }
}


resource "xenorchestra_vm" "server_other_node" {
  count       = length(data.xenorchestra_hosts.pool.hosts) > var.server_node_count ? var.server_node_count - 1 : length(data.xenorchestra_hosts.pool.hosts) - 1
  memory_max  = var.server_node_memory
  cpus        = var.server_node_cpu
  name_label  = "${var.server_host_name_prefix}-${count.index + 1}"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_server_other_node[count.index].template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_server_other_node[count.index].template
  affinity_host = data.xenorchestra_hosts.pool.hosts[count.index + 1].id
  depends_on = [ xenorchestra_vm.server_first_node ]
  tags = [
    "k3s",
    "k3s-server"
  ]

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
}


#                        )              )    ) (         (
#    (     (          ( /(   *   )   ( /( ( /( )\ )      )\ )
#    )\    )\ )   (   )\())` )  /(   )\()))\()|()/(  (  (()/(
# ((((_)( (()/(   )\ ((_)\  ( )(_)) ((_)\((_)\ /(_)) )\  /(_))
#  )\ _ )\ /(_))_((_) _((_)(_(_())   _((_) ((_|_))_ ((_)(_))
#  (_)_\(_|_)) __| __| \| ||_   _|  | \| |/ _ \|   \| __/ __|
#   / _ \   | (_ | _|| .` |  | |    | .` | (_) | |) | _|\__ \
#  /_/ \_\   \___|___|_|\_|  |_|    |_|\_|\___/|___/|___|___/

resource "xenorchestra_vm" "agent_first_node" {
  memory_max  = var.agent_node_memory
  cpus        = var.agent_node_cpu
  name_label  = "${var.agent_host_name_prefix}-0"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_agent_first_node.template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_agent_first_node.template
  affinity_host = data.xenorchestra_hosts.pool.hosts[0].id
  depends_on = [ xenorchestra_vm.server_other_node ]
  tags = [
    "k3s",
    "k3s-agent"
  ]

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
    name_label = "${var.agent_host_name_prefix}-SR-0"
    size       = 36829301760  # 36 GB in bytes
  }
}

resource "xenorchestra_vm" "agent_other_node" {
  count       = var.agent_node_count - 1
  memory_max  = var.agent_node_memory
  cpus        = var.agent_node_cpu
  name_label  = "${var.agent_host_name_prefix}-${count.index + 1}"
  template    = data.xenorchestra_template.vm_template.id
  cloud_config     = xenorchestra_cloud_config.cloud_config_agent_other_node[count.index].template
  cloud_network_config = xenorchestra_cloud_config.cloud_network_config_agent_other_node[count.index].template
  affinity_host = data.xenorchestra_hosts.pool.hosts[count.index % length(data.xenorchestra_hosts.pool.hosts)].id
  depends_on = [ xenorchestra_vm.agent_first_node ]
  tags = [
    "k3s",
    "k3s-agent"
  ]

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
}