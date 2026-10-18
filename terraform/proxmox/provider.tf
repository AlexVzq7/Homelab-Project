terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.103.0"
    }
  }
}


provider "proxmox" {
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  endpoint  = var.pm_api_url
  insecure  = true
}
