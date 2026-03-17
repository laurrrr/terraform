resource "proxmox_vm_qemu" "vm" {
  name        = "thesis-${var.name}"
  vmid        = var.vmid
  target_node = "pve"
  clone       = "debian12-template"
  full_clone  = true
  desc        = var.description

  cores    = var.cores
  sockets  = 1
  memory   = var.memory
  os_type  = "cloud-init"
  bootdisk = "scsi0"
  scsihw   = "virtio-scsi-pci"

  # Qemu guest agent — trebuie instalat in VM dupa boot
  agent = 1

  disk {
    slot    = 0
    size    = var.disk_size
    type    = "scsi"
    storage = "local-lvm"
    discard = "on"
  }

  # Retea interna intre VM-uri
  network {
    model  = "virtio"
    bridge = "vmbr1"
    tag    = -1
  }

  # Cloud-init: IP static, gateway spre Proxmox host (10.10.0.1)
  ipconfig0 = "ip=${var.ip}/24,gw=10.10.0.1"
  nameserver = "8.8.8.8 1.1.1.1"
  ciuser    = "debian"
  sshkeys   = var.ssh_public_key

  # Evita recrearea VM la schimbari minore de retea
  lifecycle {
    ignore_changes = [
      network,
      desc,
    ]
  }

  timeouts {
    create = "10m"
    delete = "5m"
  }
}
