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

variable "pm_datastore_id" {
  description = "Proxmox datastore ID"
  type        = string
  default     = "local-lvm"
}

variable "template_vm_id" {
  description = "ID of the template VM to clone"
  type        = map(number)
  default = {
    pfsense = 700
    ubuntu  = 500
    debian  = 400
    windows = 800
    kali    = 9000
  }
}

variable "node_assignment" {
  description = "Map of Proxmox node names"
  type        = map(string)
  default = {
    home    = "home"
    homelab = "homelab"
    home2   = "home2"
  }
}

variable "ssh_keys" {
  description = "List of SSH public keys to inject in the VMs"
  type        = list(string)
}

variable "vms" {
  description = "Map of VMs to create. Add an entry here to provision a new VM."
  type = map(object({
    vm_id          = number
    description    = string
    template       = string
    cores          = number
    memory         = number
    disk_size      = number
    ip             = string
    gateway        = optional(string)
    username       = string
    node           = string
    bridge         = string
    use_cloud_init = optional(bool, true)
    clone_node     = optional(string)
  }))
}

variable "default_gateway" {
  description = "Passerelle utilisée par les VM qui n'en précisent pas"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "Serveurs DNS injectés par cloud-init (netplan les remplace ensuite par dns-1)"
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]
}
