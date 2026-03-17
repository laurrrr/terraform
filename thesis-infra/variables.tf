variable "proxmox_host" {
  description = "URL API Proxmox"
  type        = string
  default     = "https://192.168.1.100:8006/api2/json"
}

variable "proxmox_user" {
  description = "User Proxmox (ex: root@pam)"
  type        = string
  default     = "root@pam"
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
