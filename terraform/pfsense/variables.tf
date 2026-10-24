variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://10.168.168.240:8006/api2/json"
}

variable "node_assignment" {
  type = map(string)
  default = {
    home    = "home"
    homelab = "homelab"
    home2   = "home2"
  }
}
