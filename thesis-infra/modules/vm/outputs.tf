output "vm_ip" {
  description = "IP-ul VM-ului"
  value       = var.ip
}

output "vm_name" {
  description = "Numele VM-ului"
  value       = proxmox_vm_qemu.vm.name
}

output "vmid" {
  description = "ID-ul VM-ului in Proxmox"
  value       = proxmox_vm_qemu.vm.vmid
}
