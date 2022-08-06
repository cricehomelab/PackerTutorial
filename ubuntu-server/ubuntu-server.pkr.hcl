
# defining variables.
variable "proxmox_api_url" {
    type = string
}
variable "proxmox_api_token" {
    type = string
}
variable "proxmox_token_secret" {
    type = string
    sensitive = true
}
variable "proxmox_ssh_password_secret" {
    type = string
    sensitive = true
}

# Resource Definition for the VM template
source "proxmox" "ubuntu-server-jammy" {
    # Proxmox connection settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token}"
    token = "${var.proxmox_token_secret}"
    # Skip TLS Verification
    insecure_skip_tls_verify = true

    node = "pve1"
    vm_id = "901"
    vm_name = "ubuntu-server"
    template_description = "Ubuntu Server template image."

    # Using local ISO
    iso_file = "local:iso/ubuntu-22.04-live-server-amd64.iso"
    iso_storage_pool = "local"
    unmount_iso = true

    #VM System Settings
    qemu_agent = true

    # VM HDD Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "32G"
        format = "raw"
        storage_pool = "local-lvm"
        storage_pool_type = "lvm"
        type = "virtio"
    }

    # CPU cores
    cores = "1"

    # Memory Settings
    memory = "2048"

    # Network Adapters
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }
    
    # Cloud Iniet settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER boot commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",    
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",   
        "<f10><wait>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER autoinstall settings
    http_directory = "C:\\temp\\packerimages\\linux\\tutorial\\ubuntu-server\\http"
    # I think this is where i can set a static IP here

    ssh_username = "charlie"
    ssh_password = "${var.proxmox_ssh_password_secret}"
    ssh_timeout = "20m"
}

build {
    name = "ubuntu-server-jammyu"
    sources = ["source.proxmox.ubuntu-server-jammy"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }
    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "C:\\temp\\packerimages\\linux\\tutorial\\ubuntu-server\\files\\99-pve.cfg"
        destination = "tmp/99-pve.cfg"
    }
    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}