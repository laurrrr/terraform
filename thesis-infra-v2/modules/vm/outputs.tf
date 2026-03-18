output "vm_ip" {
  value = var.ip
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.vm.name
}

output "vmid" {
  value = proxmox_virtual_environment_vm.vm.vm_id
}
