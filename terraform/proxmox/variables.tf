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
  default = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0Ll536wkfUywCsLcuNPqsWcVrFayLOz+u1P7vNLM7GQ+i7C8vih0n6D68YnxmAAGQTzrrkPRITQ09RCGQZtv7sXVU4AEhiHcGFnlVMddPgwcybccemH5i+r0UG5ppGlfZKjrrqqim+GEU4HnQyvZxqz4oCmBRQ1dciyszF4Jtv2Cus9G8vk1w/g8IRqQCoxYzE80M7JdPP3eDp+FqirD+nH2DYwRFLywFEKfyMj1OZgrkvRk1OlUmSmnVm1sUTmRF/KKre82hUDCcn6bTYECvWTJyti3Fi8eT5l/qagFb0dvXPxGnbI+ZJcsL3I1yGB0iRuAnL6caUR6aNq0eUNX371zvhd6iMxECvM9HrGOuCRMo6pgnu37fCcTMWA/C3VuWj4wN1IWs+a0mY+hX9KAwLJDCLZVckvmhQFWliQG35KOYbXMCHyiyl2YQs87iIFSli0MB42lWBMjoeqoIj0ckqvHJCnQYKzX4toGH1nTRZEeedgY5eeyUo9dCPPTtyjfdGf3T/6z5AiLLN80rpYKAe3TRkMPdl8YMPYJHsPrBWqbgZPDF/Jb9NopKbYIgUpCSAGwq8I2k+buymNPNfpFUTZBGAtCha++4J8Pc58dogVqAgdMVDApImNpxfI+gf3UqLClKSHZUBBuHzrQpFBAMiVeYukaKL0Eyxvs3JMjK1w== alex@DESKTOP-4GMOER2",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDANs1h/zQvEYLvPRdjD+gor20o/cmnhTd92HitN5VjItTg4V3LBRa+g/qZmgC1zHOmNhqauWI5H6y/RQc/BVX0579ff5p9jPU0O4EqvSC90MMWqdpmuL1I1b/3185l8N1JsynQTkQGUvPihovO1ZZlhvkT3rxw2jnGneR7xx1MAFrdKi1l1wLXGA9owJwmTPZrOhoRVY8JGHLmoU5zkWIM7iypwfBii5NWKJNURFPe8lrQJULkIOBke3TLtTF2qPWe9JRizFzsFvDTr+/z/3jQNDvtJwKu0jvo41TFOZpWTJMM691rrU4TnZnhZKc+mpgKpaVmA1Z4GgfAVGCLdORgBQFeK5F+ff0g95vPZTZgEb+mdRoox9gJVsSvfP+msYR6bAtnUDeJNgeFw8CMW37KLwbTq/rQlcx/Pjw72LzZUp/wNHELqlRSUXHxmVupfoQ1Ij7+F259iZMk93uno0VYmOz3L1lsx2EG5VnQqX7U4KLka4huOk5A/PxuVWeLzIq9xOedDpwsAOSOv+0cwDHOpPUnjthCK3s2/a7JgTeJP31RUZa9SiwPKziWVoDy+69MYQ2LaCZi/VSmfqhiNVJy3HGylJ31X69ea8rN7XzL4KT+7oADM6hLGmYdgVEoFlIRGQCPcfUEeIqATx33l8g1FPIHi2FujBZdUtRWqygD8w== driss@driss-OptiPlex-7010",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCo7DCFEdSIvyewpAkgqLzfc78Smu0B6qEwNrQvCTzijl+NqH3quULyxHZFe2NMbtGyW/9K6Q6K0vVGDu6ah4fj+xwelwKzp4WPXwTHasrt7cllVCyjHPt5mVcPhhwqXT6BMll3Bdv2rPR4m0QDPL7Nzl4SVMmvqkb9y+iTSf6fcbpcfM3+f6RyK9xg8+MWITIYSTMLW1AjyD6mUeeq/KvfuDIBjpa5t9tjPvlUueIVL2SsHbKgvGUTmb0gGKvEH/Gf7Qi4W+o8CKzUgU2QNniYkkuSwfj+qTCKWLRqgfi3wmPkg4N97fy6iSdPDNFYHrsrBHXjD65bJmzON4zAgbeaDGRxlJWRqk5CXjhCM6udvHGHhJIojf83yGTpWvqrdLU2mmnG7cmtwCXd0o3Bu1hm296VzI4aEV5gf8EyT5659mt2dOD3GJkiBwHvXpMjyCf0MHJsRPliJYtieG1l8Uo3w3WzV962MdcYC3pJz+F734u9dZ5ge8r1KVQLK/g7+xVfvtQyLxnhVfdB5UMDKz/xZULJ/YS35/2+oYFBHnMXZXZPANtKlIH4RufKSK/ia7+QwuE735K0oxr2lEjQo5aAiXe3zzNpfxMnOk+7msRXt15/wgD0QDNwvzHUAkcLFgThY9NydV7wI65kQztdZjkuDOopltS08f//qJ1blj/2Ow== root@ansible-node",
  ]
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
    gateway        = string
    username       = string
    node           = string
    bridge         = string
    use_cloud_init = optional(bool, true)
    clone_node     = optional(string)
  }))
  default = {
    "openldap-1" = {
      vm_id       = 401
      description = "OpenLDAP server for homelab"
      template    = "debian"
      cores       = 2
      memory      = 1024
      disk_size   = 20
      ip          = "192.168.1.103/24"
      gateway     = "192.168.1.1"
      username    = "debian"
      node        = "home"
      bridge      = "VnetLan"
    }

    "vault" = {
      vm_id       = 402
      description = "Vault server for homelab"
      template    = "debian"
      cores       = 2
      memory      = 2048
      disk_size   = 20
      ip          = "192.168.1.104/24"
      gateway     = "192.168.1.1"
      username    = "debian"
      node        = "home"
      bridge      = "VnetLan"
    }
    "ca" = {
      vm_id       = 403
      description = "CA server for homelab"
      template    = "debian"
      cores       = 1
      memory      = 512
      disk_size   = 20
      ip          = "192.168.1.105/24"
      gateway     = "192.168.1.1"
      username    = "debian"
      node        = "home"
      bridge      = "VnetLan"
    }
    "dns-1" = {
      vm_id       = 404
      description = "BIND9 DNS server for homelab"
      template    = "debian"
      cores       = 1
      memory      = 512
      disk_size   = 20
      ip          = "192.168.1.106/24"
      gateway     = "192.168.1.1"
      username    = "debian"
      node        = "home"
      bridge      = "VnetLan"
    }
  }
}
