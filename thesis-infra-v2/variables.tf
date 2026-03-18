variable "proxmox_host" {
  description = "URL API Proxmox"
  type        = string
  default     = "https://192.168.1.100:8006"
}

variable "proxmox_user" {
  description = "User Proxmox"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_password" {
  description = "Parola Proxmox"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Cheia SSH publica pentru acces pe VM-uri"
  type        = string
}

variable "vm_password" {
  description = "Parola root/debian pe toate VM-urile"
  type        = string
  sensitive   = true
  default     = "Thesis2024!"
}
