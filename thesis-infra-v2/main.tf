terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_host
  username  = var.proxmox_user
  password  = var.proxmox_password
  insecure  = true
}

locals {
  vms = {
    nginx = {
      vmid        = 100
      ip          = "10.10.0.9"
      cores       = 1
      memory      = 512
      disk        = "8G"
      description = "Nginx - Reverse Proxy"
      nbd_slot    = 0
    }
    acs = {
      vmid        = 101
      ip          = "10.10.0.10"
      cores       = 4
      memory      = 4096
      disk        = "20G"
      description = "GenieACS - Auto Configuration Server (TR-069)"
      nbd_slot    = 1
    }
    api = {
      vmid        = 102
      ip          = "10.10.0.11"
      cores       = 2
      memory      = 4096
      disk        = "15G"
      description = "FastAPI - REST layer + Redis"
      nbd_slot    = 2
    }
    db = {
      vmid        = 103
      ip          = "10.10.0.12"
      cores       = 4
      memory      = 16384
      disk        = "40G"
      description = "MongoDB - device records, sessions, job logs"
      nbd_slot    = 3
    }
    grafana = {
      vmid        = 104
      ip          = "10.10.0.13"
      cores       = 4
      memory      = 8192
      disk        = "20G"
      description = "Grafana + Prometheus + AlertManager"
      nbd_slot    = 4
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
  vm_password    = var.vm_password
  nbd_slot       = each.value.nbd_slot
}

# iptables + NAT pe Proxmox host — ruleaza dupa toate VM-urile
resource "null_resource" "host_network_setup" {
  depends_on = [module.vms]

  provisioner "local-exec" {
    command = <<-SCRIPT
      set -e

      echo "=== IP Forwarding ==="
      cat > /etc/sysctl.d/99-forwarding.conf << 'EOF'
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
EOF
      sysctl --system

      echo "=== Reset iptables ==="
      iptables -F
      iptables -X
      iptables -t nat -F
      iptables -t nat -X
      iptables -t mangle -F
      iptables -t mangle -X

      echo "=== Politici default ==="
      iptables -P INPUT DROP
      iptables -P FORWARD DROP
      iptables -P OUTPUT ACCEPT

      echo "=== Reguli INPUT ==="
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
      iptables -A INPUT -m state --state INVALID -j DROP

      # Proxmox Web UI (8006) — LAN local + IP tau
      iptables -A INPUT -i enp2s0 -p tcp --dport 8006 -s 192.168.1.0/24 -j ACCEPT
      iptables -A INPUT -i enp2s0 -p tcp --dport 8006 -s 212.54.122.93/32 -j ACCEPT

      # SSH — LAN local + IP tau
      iptables -A INPUT -i enp2s0 -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
      iptables -A INPUT -i enp2s0 -p tcp --dport 22 -s 212.54.122.93/32 -j ACCEPT

      # ICMP ping
      iptables -A INPUT -p icmp --icmp-type echo-request -s 192.168.1.0/24 -j ACCEPT
      iptables -A INPUT -p icmp --icmp-type echo-request -s 212.54.122.93/32 -j ACCEPT
      iptables -A INPUT -p icmp --icmp-type echo-request -s 10.10.0.0/24 -j ACCEPT

      # Trafic de la VM-uri spre host
      iptables -A INPUT -i vmbr1 -s 10.10.0.0/24 -j ACCEPT

      # Log + drop rest
      iptables -A INPUT -j LOG --log-prefix "IPT-INPUT-DROP: " --log-level 4
      iptables -A INPUT -j DROP

      echo "=== Reguli FORWARD ==="
      iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -m state --state INVALID -j DROP

      # VM-uri -> Internet
      iptables -A FORWARD -i vmbr1 -o enp2s0 -s 10.10.0.0/24 -j ACCEPT

      # Inter-VM (vmbr1 <-> vmbr1)
      iptables -A FORWARD -i vmbr1 -o vmbr1 -s 10.10.0.0/24 -d 10.10.0.0/24 -j ACCEPT

      # Log + drop rest
      iptables -A FORWARD -j LOG --log-prefix "IPT-FORWARD-DROP: " --log-level 4
      iptables -A FORWARD -j DROP

      echo "=== NAT ==="
      iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o enp2s0 -j MASQUERADE

      echo "=== Salveaza iptables ==="
      apt-get install -y -q iptables-persistent
      netfilter-persistent save

      echo "=== Host network setup GATA ==="
    SCRIPT
  }
}
