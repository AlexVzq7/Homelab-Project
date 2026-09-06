# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform
resource "proxmox_virtual_environment_vm" "ubuntu_GUI" {
  acpi                                 = true
  bios                                 = "seabios"
  boot_order                           = ["scsi0", "ide2", "net0"]
  delete_unreferenced_disks_on_destroy = true
  description                          = null
  hook_script_file_id                  = null
  keyboard_layout                      = null
  kvm_arguments                        = null
  mac_addresses                        = ["00:00:00:00:00:00", "BC:24:11:BA:13:87"]
  machine                              = null
  migrate                              = false
  name                                 = "Ubuntu-gui"
  network_device = [{
    bridge       = "VnetLan"
    disconnected = false
    enabled      = true
    firewall     = true
    mac_address  = "BC:24:11:BA:13:87"
    model        = "virtio"
    mtu          = 0
    queues       = 0
    rate_limit   = 0
    trunks       = ""
    vlan_id      = 0
  }]
  node_name           = "home"
  on_boot             = false
  pool_id             = null
  protection          = false
  purge_on_destroy    = true
  reboot              = false
  reboot_after_update = true
  scsi_hardware       = "virtio-scsi-single"
  started             = true
  stop_on_destroy     = false
  tablet_device       = true
  tags                = []
  template            = false
  timeout_clone       = 1800
  timeout_create      = 1800
  timeout_migrate     = 1800
  timeout_reboot      = 1800
  timeout_shutdown_vm = 1800
  timeout_start_vm    = 1800
  timeout_stop_vm     = 300
  vm_id               = 101
  agent {
    enabled = true
    timeout = "15m"
    trim    = false
    type    = null
  }
  cpu {
    affinity     = null
    architecture = null
    cores        = 2
    flags        = []
    hotplugged   = 0
    limit        = 0
    numa         = false
    sockets      = 1
    type         = "host"
  }
  disk {
    aio               = "io_uring"
    backup            = true
    cache             = "none"
    datastore_id      = "local"
    discard           = "ignore"
    file_format       = "qcow2"
    file_id           = null
    import_from       = null
    interface         = "scsi0"
    iothread          = true
    path_in_datastore = "101/vm-101-disk-0.qcow2"
    replicate         = true
    serial            = null
    size              = 32
    ssd               = false
  }
  memory {
    dedicated      = 3062
    floating       = 0
    hugepages      = null
    keep_hugepages = false
    shared         = 0
  }
  operating_system {
    type = "l26"
  }
  vga {
    clipboard = "vnc"
    memory    = 16
    type      = "qxl"
  }
}
