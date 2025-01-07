terraform {
  required_providers {
    xenorchestra = {
      source = "registry.opentofu.org/vatesfr/xenorchestra"
      version = "~> 0.29"
    }
  }
}

provider "xenorchestra" {
  url      = var.XOA_URL
  username = var.XOA_USER
  password = var.XOA_PASSWORD
  insecure = true
}


