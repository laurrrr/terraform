variable "name" {
  description = "Numele VM-ului"
  type        = string
}

variable "vmid" {
  description = "ID unic VM in Proxmox"
  type        = number
}

variable "ip" {
  description = "IP static pe reteaua interna (vmbr1)"
  type        = string
}

variable "cores" {
  description = "Numar de core-uri CPU (poate fi mai mare decat fizic - overcommit)"
  type        = number
}

variable "memory" {
  description = "RAM in MB"
  type        = number
}

variable "disk_size" {
  description = "Dimensiune disc (ex: 20G)"
  type        = string
}

variable "description" {
  description = "Descriere VM"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "Cheia SSH publica"
  type        = string
}

variable "vm_password" {
  description = "Parola root pe VM"
  type        = string
  sensitive   = true
}

variable "nbd_slot" {
  description = "Slot nbd unic per VM (0-7) pentru montare disc"
  type        = number
  default     = 0
}
