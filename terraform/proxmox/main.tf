resource "proxmox_virtual_environment_vm" "vm" {
  for_each    = var.vms
  name        = each.key
  node_name   = var.node_assignment[each.value.node]
  description = each.value.description
  vm_id       = each.value.vm_id

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.pm_datastore_id
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  clone {
    node_name    = var.node_assignment[coalesce(each.value.clone_node, each.value.node)]
    full         = true
    vm_id        = var.template_vm_id[each.value.template]
    datastore_id = var.pm_datastore_id
  }

  network_device {
    bridge = each.value.bridge
    model  = "virtio"
  }

  agent {
    enabled = true
    timeout = "20s"
  }

  dynamic "initialization" {
    for_each = each.value.use_cloud_init ? [1] : []
    content {
      dns {
        servers = ["8.8.8.8", "1.1.1.1"]
      }
      ip_config {
        ipv4 {
          address = each.value.ip
          gateway = each.value.gateway
        }
      }
      user_account {
        username = each.value.username
        keys     = var.ssh_keys
      }
    }
  }
}
