#  (       (              (         )    ) (         (
#  )\ )    )\ )           )\ )   ( /( ( /( )\ )      )\ )
# (()/((  (()/((   (  (  (()/(   )\()))\()|()/(  (  (()/(
#  /(_))\  /(_))\  )\ )\  /(_)) ((_)\((_)\ /(_)) )\  /(_))
# (_))((_)(_))((_)((_|(_)(_))    _((_) ((_|_))_ ((_)(_))
# / __| __| _ \ \ / /| __| _ \  | \| |/ _ \|   \| __/ __|
# \__ \ _||   /\ V / | _||   /  | .` | (_) | |) | _|\__ \
# |___/___|_|_\ \_/  |___|_|_\  |_|\_|\___/|___/|___|___/

resource "xenorchestra_cloud_config" "cloud_config_server_first_node" {
  name      = "Hosted VM Cloud-Init: User-Data"
  template  = templatefile(
    "./cloud-init/cloud-init-server-first-node.tftpl",
    {
      count                   = 0,
      host_name_prefix        = "${var.server_host_name_prefix}",
      ssh_public_key          = file(".ssh/id_rsa_pub"),
      k3s_token               = file(".k3s/k3s_token"),
      server_alb_ip           = "${var.server_alb_ip}",
      server_start_ip        = "${var.server_start_ip}",
      metallb_yaml            = indent(6, templatefile("./metallb/metallb-address-pool.yaml", {
        agent_alb_primary_ip = var.agent_alb_primary_ip
        agent_alb_additional_ips    = "${var.agent_alb_additional_ips}"
      })),
      ssh_administrator_username = "${var.SSH_ADMINISTRATOR_USERNAME}"
      ssh_administrator_password = "${var.SSH_ADMINISTRATOR_PASSWORD}"

      # cert-manager
      with_cert_manager                                 = var.with_cert_manager,
      cert_manager_issuer_environment                   = local.cert_manager_issuer_environment,
      cert_manager_chart_values                         = indent(6, templatefile("./deployments/cert-manager/chart-values.yaml", {
      })),
      cert_manager_issuers_secret_cf_token              = indent(6, templatefile("./deployments/cert-manager/issuers/secret-cf-token.yaml", {
        cert_manager_cloudflare_api_token               = var.CERT_MANAGER_CLOUDFLARE_API_TOKEN
      })),
      cert_manager_issuers_letsencrypt_issuer           = indent(6, templatefile("./deployments/cert-manager/issuers/letsencrypt-${local.cert_manager_issuer_environment}.yaml", {
        cert_manager_letsencrypt_email                  = var.CERT_MANAGER_LETSENCRYPT_EMAIL,
        cert_manager_cloudflare_email                   = var.CERT_MANAGER_CLOUDFLARE_EMAIL,
        cert_manager_cloudflare_dns_zone                = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
      })),
      cert_manager_certificates_environment_certificate = indent(6, templatefile("./deployments/cert-manager/certificates/${local.cert_manager_issuer_environment}/certificate.yaml", {
        cert_manager_cloudflare_dns_secret_name_prefix  = var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX,
        cert_manager_cloudflare_dns_zone                = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
      }))

      # traefik
      with_traefik                                      = var.with_traefik,
      traefik_chart_values                              = indent(6, templatefile("./deployments/traefik/chart-values.yaml", {
        agent_alb_primary_ip                            = "${var.agent_alb_primary_ip}",
        agent_alb_additional_ips                        = var.agent_alb_additional_ips
      })),
      traefik_traefik_dashboard_auth                    = indent(6, templatefile("./deployments/traefik/traefik-dashboard-auth.yaml", {
        traefik_dashboard_auth                          = "${var.TRAEFIK_DASHBOARD_AUTH}"
      })),
      traefik_traefik_dashboard_ingress                 = indent(6, templatefile("./deployments/traefik/traefik-dashboard-ingress.yaml", {
        traefik_dashboard_fqdn                          = "${var.TRAEFIK_DASHBOARD_FQDN}",
        cert_manager_cloudflare_dns_secret_name_prefix  = "${var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX}",
        cert_manager_issuer_environment                 = local.cert_manager_issuer_environment
      })),
      traefik_traefik_dashboard_middleware              = indent(6, templatefile("./deployments/traefik/traefik-dashboard-middleware.yaml", {
      })),
      traefik_traefik_default_headers                   = indent(6, templatefile("./deployments/traefik/traefik-default-headers.yaml", {
      })),
      traefik_certificates_environment_certificate      = indent(6, templatefile("./deployments/traefik/certificates/${local.cert_manager_issuer_environment}/traefik-certificate.yaml", {
        cert_manager_cloudflare_dns_secret_name_prefix        = var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX,
        cert_manager_cloudflare_dns_zone                      = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
        traefik_dashboard_fqdn                                = var.TRAEFIK_DASHBOARD_FQDN
      })),

      # k8s dashboard
      with_k8s_dashboard                                = var.with_k8s_dashboard,
      kubernetes_chart_values                           = indent(6, templatefile("./deployments/kubernetes-dashboard/chart-values.yaml", {
      })),
      kubernetes_dashboard_admin_user_role              = indent(6, templatefile("./deployments/kubernetes-dashboard/k8s-dashboard-admin-user-role.yaml", {
      })),
      kubernetes_dashboard_admin_user                   = indent(6, templatefile("./deployments/kubernetes-dashboard/k8s-dashboard-admin-user.yaml", {
      })),
      kubernetes_dashboard_ingress                      = indent(6, templatefile("./deployments/kubernetes-dashboard/k8s-dashboard-ingress.yaml", {
        kubernetes_dashboard_fqdn                               = "${var.KUBERNETES_DASHBOARD_FQDN}",
        kubernetes_dashboard_cloudflare_dns_secret_name_prefix  = "${var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX}",
        kubernetes_dashboard_issuer_environment                 = local.cert_manager_issuer_environment
      })),
      kubernetes_dashboard_certificates_environment_certificate       = indent(6, templatefile("./deployments/kubernetes-dashboard/certificates/${local.cert_manager_issuer_environment}/kubernetes-dashboard-certificate.yaml", {
        kubernetes_dashboard_cloudflare_dns_secret_name_prefix        = var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX,
        kubernetes_dashboard_fqdn                                     = var.KUBERNETES_DASHBOARD_FQDN
      }))


      # rancher
      with_rancher_dashboard                                = "${var.with_rancher_dashboard}",
      bootstrap_password                                    = "${var.RANCHER_BOOTSTRAP_PASSWORD}",
      rancher_dashboard_fqdn                                = "${var.RANCHER_DASHBOARD_FQDN}",
      cert_manager_letsencrypt_email                        = "${var.CERT_MANAGER_LETSENCRYPT_EMAIL}"
      rancher_dashboard_service                             = indent(6, templatefile("./deployments/rancher-dashboard/rancher-dashboard-service.yaml", {
        load_balancer_ip                                    = "${var.rancher_load_balancer_ip}"
      })),
      rancher_dashboard_middlewware                         = indent(6, templatefile("./deployments/rancher-dashboard/rancher-dashboard-middleware.yaml", {
      })),
      rancher_dashboard_ingress                             = indent(6, templatefile("./deployments/rancher-dashboard/rancher-dashboard-ingress.yaml", {
        rancher_dashboard_fqdn                              = "${var.RANCHER_DASHBOARD_FQDN}",
        cert_manager_cloudflare_dns_secret_name_prefix      = "${var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX}",
        cert_manager_issuer_environment                     = "${local.cert_manager_issuer_environment}"
      })),
      rancher_dashboard_certificates_environment_certificate      = indent(6, templatefile("./deployments/rancher-dashboard/certificates/${local.cert_manager_issuer_environment}/rancher-dashboard-certificate.yaml", {
        cert_manager_cloudflare_dns_secret_name_prefix            = "${var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX}",
        rancher_dashboard_fqdn                                    = var.RANCHER_DASHBOARD_FQDN
      }))
    }
  )
}

resource "xenorchestra_cloud_config" "cloud_network_config_server_first_node" {
  name      = "Hosted VM Cloud-Init: Network"
  template  = templatefile(
    "./cloud-init/cloud-init-networks-static.tftpl",
    {
      ip_address              = "${var.server_start_ip}"
      ip_subnet_mask          = "${var.server_subnet_mask}"
      ip_internal_gateway     = "${var.INTERNAL_GATEWAY_IP}"
      ip_internal_dns_servers = "${var.INTERNAL_DNS_SERVERS}"
      internal_domain         = "${var.INTERNAL_DOMAIN}"
    }
  )
}

resource "xenorchestra_cloud_config" "cloud_config_server_other_node" {
  count     = length(data.xenorchestra_hosts.pool.hosts) - 1
  name      = "Hosted VM Cloud-Init: User-Data"
  template  = templatefile(
    "./cloud-init/cloud-init-server-other-node.tftpl",
    {
      count                 = count.index + 1,
      host_name_prefix      = var.server_host_name_prefix,
      ssh_public_key        = file(".ssh/id_rsa_pub"),
      k3s_token             = file(".k3s/k3s_token"),
      server_alb_ip         = var.server_alb_ip,
      server_start_ip       = "${var.server_start_ip}"
      ssh_administrator_username = "${var.SSH_ADMINISTRATOR_USERNAME}"
      ssh_administrator_password = "${var.SSH_ADMINISTRATOR_PASSWORD}"
    }
  )
}


resource "xenorchestra_cloud_config" "cloud_network_config_server_other_node" {
  count                     = length(data.xenorchestra_hosts.pool.hosts) - 1
  name                      = "Hosted VM Cloud-Init: Network"
  template                  = templatefile(
    "./cloud-init/cloud-init-networks-static.tftpl",
    {
      ip_address              = data.external.next_ip[count.index].result.next_ip
      ip_subnet_mask          = "${var.server_subnet_mask}"
      ip_internal_gateway     = "${var.INTERNAL_GATEWAY_IP}"
      ip_internal_dns_servers = "${var.INTERNAL_DNS_SERVERS}"
      internal_domain         = "${var.INTERNAL_DOMAIN}"
    }
  )
}


#                        )              )    ) (         (
#    (     (          ( /(   *   )   ( /( ( /( )\ )      )\ )
#    )\    )\ )   (   )\())` )  /(   )\()))\()|()/(  (  (()/(
# ((((_)( (()/(   )\ ((_)\  ( )(_)) ((_)\((_)\ /(_)) )\  /(_))
#  )\ _ )\ /(_))_((_) _((_)(_(_())   _((_) ((_|_))_ ((_)(_))
#  (_)_\(_|_)) __| __| \| ||_   _|  | \| |/ _ \|   \| __/ __|
#   / _ \   | (_ | _|| .` |  | |    | .` | (_) | |) | _|\__ \
#  /_/ \_\   \___|___|_|\_|  |_|    |_|\_|\___/|___/|___|___/

resource "xenorchestra_cloud_config" "cloud_config_agent_first_node" {
  name      = "Hosted VM Cloud-Init: User-Data"
  template  = templatefile(
    "./cloud-init/cloud-init-agent-first-node.tftpl",
    {
      count                   = 0
      host_name_prefix        = var.agent_host_name_prefix
      ssh_public_key          = file(".ssh/id_rsa_pub")
      k3s_token               = file(".k3s/k3s_token")
      server_alb_ip           = var.server_alb_ip
      server_start_ip         = "${var.server_start_ip}"
      ssh_administrator_username = "${var.SSH_ADMINISTRATOR_USERNAME}"
      ssh_administrator_password = "${var.SSH_ADMINISTRATOR_PASSWORD}"
    }
  )
}


resource "xenorchestra_cloud_config" "cloud_network_config_agent_first_node" {
  name                      = "Hosted VM Cloud-Init: Network"
  template                  = templatefile(
    "./cloud-init/cloud-init-networks-dhcp.tftpl",
    {
      ip_internal_gateway     = "${var.INTERNAL_GATEWAY_IP}"
      ip_internal_dns_servers = "${var.INTERNAL_DNS_SERVERS}"
      internal_domain         = "${var.INTERNAL_DOMAIN}"
    }
  )
}


resource "xenorchestra_cloud_config" "cloud_config_agent_other_node" {
  count                     = var.agent_node_count - 1
  name                      = "Hosted VM Cloud-Init: User-Data"
  template                  = templatefile(
    "./cloud-init/cloud-init-agent-other-node.tftpl",
    {
      count                 = count.index + 1
      host_name_prefix      = var.agent_host_name_prefix
      ssh_public_key        = file(".ssh/id_rsa_pub")
      k3s_token             = file(".k3s/k3s_token")
      server_alb_ip         = var.server_alb_ip
      server_start_ip       = "${var.server_start_ip}"
      ssh_administrator_username = "${var.SSH_ADMINISTRATOR_USERNAME}"
      ssh_administrator_password = "${var.SSH_ADMINISTRATOR_PASSWORD}"
    }
  )
}


resource "xenorchestra_cloud_config" "cloud_network_config_agent_other_node" {
  count                     = var.agent_node_count
  name                      = "Hosted VM Cloud-Init: Network"
  template                  = templatefile(
    "./cloud-init/cloud-init-networks-dhcp.tftpl",
    {
      ip_internal_gateway     = "${var.INTERNAL_GATEWAY_IP}"
      ip_internal_dns_servers = "${var.INTERNAL_DNS_SERVERS}"
      internal_domain         = "${var.INTERNAL_DOMAIN}"
    }
  )
}
