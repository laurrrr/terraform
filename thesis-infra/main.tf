terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_host
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
  pm_log_enable   = false
}

locals {
  vms = {
    acs = {
      vmid        = 101
      ip          = "10.10.0.10"
      cores       = 2
      memory      = 4096
      disk        = "20G"
      description = "GenieACS - Auto Configuration Server (TR-069)"
    }
    api = {
      vmid        = 102
      ip          = "10.10.0.11"
      cores       = 2
      memory      = 4096
      disk        = "15G"
      description = "FastAPI - REST layer + Celery worker + Redis"
    }
    db = {
      vmid        = 103
      ip          = "10.10.0.12"
      cores       = 2
      memory      = 16384
      disk        = "40G"
      description = "MongoDB - device records, sessions, job logs"
    }
    grafana = {
      vmid        = 104
      ip          = "10.10.0.13"
      cores       = 2
      memory      = 8192
      disk        = "20G"
      description = "Grafana + Prometheus + AlertManager"
    }
  }
}

module "vms" {
  source   = "./modules/vm"
  for_each = local.vms

  name           = each.key
  vmid           = each.value.vmid
  ip             = each.value.ip
  cores          = each.value.cores
  memory         = each.value.memory
  disk_size      = each.value.disk
  description    = each.value.description
  ssh_public_key = var.ssh_public_key
}
