terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name        = "thesis-${var.name}"
  node_name   = "pve"
  vm_id       = var.vmid
  description = var.description
  on_boot     = true

  # Nu porni automat — il pornim noi dupa ce dezactivam KVM
  started = false

  cpu {
    cores = var.cores
    type  = "qemu64"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = tonumber(trimsuffix(var.disk_size, "G"))
    interface    = "scsi0"
    file_format  = "raw"
    discard      = "on"
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  agent {
    enabled = false
  }

  clone {
    vm_id = 9000
    full  = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip}/24"
        gateway = "10.10.0.1"
      }
    }
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
      password = var.vm_password
    }
  }

  lifecycle {
    ignore_changes = [started]
  }
}

# Dupa creare: dezactiveaza KVM, aplica cloud-init, porneste VM-ul
resource "null_resource" "vm_start" {
  depends_on = [proxmox_virtual_environment_vm.vm]

  provisioner "local-exec" {
    command = <<-SCRIPT
      set -e
      VMID=${var.vmid}
      IP=${var.ip}

      echo "=== VM $VMID: Dezactiveaza KVM ==="
      qm set $VMID --kvm 0
      qm set $VMID -args "-machine accel=tcg"

      echo "=== VM $VMID: Aplica cloud-init ==="
      qm cloudinit update $VMID

      echo "=== VM $VMID: Pornire ==="
      qm start $VMID

      echo "=== VM $VMID: Astept 60s sa booteze ==="
      sleep 60

      echo "=== VM $VMID: Configureaza reteaua via nbd ==="
      modprobe nbd max_part=8 || true

      # Asteapta sa fie disponibil discul
      for i in $(seq 1 10); do
        if qemu-nbd --connect=/dev/nbd${var.nbd_slot} /dev/pve/vm-${var.vmid}-disk-0 --format=raw 2>/dev/null; then
          break
        fi
        sleep 5
      done

      sleep 2
      mount /dev/nbd${var.nbd_slot}p1 /mnt/vm-${var.vmid} 2>/dev/null || mkdir -p /mnt/vm-${var.vmid}

      # Configureaza systemd-networkd
      mkdir -p /mnt/vm-${var.vmid}/etc/systemd/network
      cat > /mnt/vm-${var.vmid}/etc/systemd/network/10-eth.network << EOF
[Match]
Name=enp*

[Network]
Address=$IP/24
Gateway=10.10.0.1
DNS=8.8.8.8
DNS=1.1.1.1
EOF

      # Activeaza systemd-networkd
      chroot /mnt/vm-${var.vmid} systemctl enable systemd-networkd 2>/dev/null || true

      umount /mnt/vm-${var.vmid} 2>/dev/null || true
      qemu-nbd --disconnect /dev/nbd${var.nbd_slot} 2>/dev/null || true

      echo "=== VM $VMID gata ==="
    SCRIPT
  }
}
