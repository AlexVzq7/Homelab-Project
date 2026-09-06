resource "null_resource" "pfsense_config_iso" {
  triggers = {
    config_hash = filemd5("${path.module}/config.xml")
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${path.module}/iso_root/conf
      cp ${path.module}/config.xml ${path.module}/iso_root/conf/config.xml
      genisoimage -V PFSENSE -J -R -o ${path.module}/pfsense-config.iso ${path.module}/iso_root
      rm -rf ${path.module}/iso_root
    EOT
  }
}

resource "proxmox_virtual_environment_file" "config_drive" {
  depends_on   = [null_resource.pfsense_config_iso]
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_assignment["home"]
  source_file {
    path = "${path.module}/pfsense-config.iso"
  }
}

resource "proxmox_virtual_environment_vm" "pfsense" {
  name        = "pfsense"
  node_name   = var.node_assignment["home"]
  started     = true
  description = "Pfsense firewall for homelab"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  clone {
    node_name    = var.node_assignment["home"]
    full         = true
    vm_id        = var.template_vm_id
    datastore_id = "local-lvm"
  }

  agent {
    enabled = false
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  initialization {
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  cdrom {
    file_id   = proxmox_virtual_environment_file.config_drive.id
    interface = "ide2"
  }

  boot_order = ["scsi0", "ide2"]
}
