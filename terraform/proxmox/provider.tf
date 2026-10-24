terraform {

  required_version = ">= 1.8.0"

  backend "pg" {
    schema_name = "proxmox"
  }

  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }
    method "unencrypted" "migration" {}

    state {
      method = method.aes_gcm.state
      fallback {
        method = method.unencrypted.migration
      }
    }
    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }

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
