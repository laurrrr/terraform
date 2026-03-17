output "vm_ips" {
  description = "IP-urile tuturor VM-urilor create"
  value = {
    for name, mod in module.vms :
    name => mod.vm_ip
  }
}

output "ssh_commands" {
  description = "Comenzi SSH pentru fiecare VM"
  value = {
    for name, mod in module.vms :
    name => "ssh debian@${mod.vm_ip}"
  }
}
