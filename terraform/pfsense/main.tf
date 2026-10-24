# pfSense réel (VM 100), créé à la main puis importé dans le state.
# Ce code décrit la VM telle qu'elle est, il ne la recrée pas.
resource "proxmox_virtual_environment_vm" "pfsense" {
  name       = "Pfsense"
  node_name  = var.node_assignment["home"]
  vm_id      = 100
  started    = true
  on_boot    = true
  tags       = []
  boot_order = ["scsi0", "ide2", "net0"]

  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local"
    interface    = "scsi0"
    file_format  = "qcow2"
    size         = 32
    iothread     = true
  }

  # WAN
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    firewall    = true
    mac_address = "BC:24:11:7D:36:48"
  }

  # LAN homelab
  network_device {
    bridge      = "VnetLan"
    model       = "virtio"
    firewall    = true
    mac_address = "BC:24:11:96:E1:C9"
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    prevent_destroy = true # jamais de destruction de pfSense par tofu
  }
}
