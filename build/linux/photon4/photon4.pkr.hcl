# ----------------------------------------------------------------------------
# Name:         photon4.pkr.hcl
# Description:  Build definition for Photon 4
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/v12n-io/packer
# Date:         26/02/2021
# ----------------------------------------------------------------------------

# -------------------------------------------------------------------------- #
#                           Variable Definitions                             #
# -------------------------------------------------------------------------- #
# vCenter Credentials
variable "vcenter_username" {
    type        = string
    description = "The username Packer will use to login to vCenter"
    sensitive   = true
}
variable "vcenter_password" {
    type        = string
    description = "The password Packer will use to login to vCenter"
    sensitive   = true
}

# vCenter Configuration
variable "vcenter_server" {
    type        = string
    description = "The FQDN of vCenter"
}
variable "vcenter_datacenter" {
    type        = string
    description = "The name of the vSphere datacenter that Packer will use"
}
variable "vcenter_cluster" {
    type        = string
    description = "The name of the vSphere cluster that Packer will use"
}
variable "vcenter_datastore" {
    type        = string
    description = "The name of the datastore where Packer will create templates"
}
variable "vcenter_network" {
    type        = string
    description = "The name of the network that Packer will attache templates to"
}

# vCenter and ISO Configuration
variable "vcenter_iso_datastore" {
    type        = string
    description = "The name of the datastore where Packer will attach ISO files from"
}
variable "os_iso_file" {
    type        = string
    description = "The name of the ISO file to be used for OS installation"
}
variable "os_iso_path" {
    type        = string
    description = "The path of the ISO file to be used for OS installation"
}

# OS Meta Data
variable "os_family" {
    type        = string
    description = "The family that guest OS belongs to (e.g. Windows, RedHat or CentOS etc)"
}
variable "os_version" {
    type        = string
    description = "The major version of guest OS that will be installed (e.g. 2019, 8, 4 etc)"
}

# Virtual Machine OS Settings
# See https://vdc-download.vmware.com/vmwb-repository/dcr-public/da47f910-60ac-438b-8b9b-6122f4d14524/16b7274a-bf8b-4b4c-a05e-746f2aa93c8c/doc/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html
variable "vm_os_type" {
    type        = string
    description = "The vSphere guest OS identifier"
}

# Virtual Machine Hardware Settings
variable "vm_firmware" {
    type        = string
    description = "The type of firmware for the VM"
    default     = "bios"
}
variable "vm_cpu_sockets" {
    type        = number
    description = "The number of 'physical' CPUs to be configured on the VM"
}
variable "vm_cpu_cores" {
    type        = number
    description = "The number of cores to be configured per CPU on the VM"
}
variable "vm_mem_size" {
    type        = number
    description = "The size of the VM's virtual memory (in Mb)"
}
variable "vm_nic_type" {
    type        = string
    description = "The type of network interface to configure on the VM"
}
variable "vm_disk_controller" {
    type        = list(string)
    description = "A list of the disk controller types to be configured (in order)"
}
variable "vm_disk_size" {
    type        = number
    description = "The size of the VM's system disk (in Mb)"
}
variable "vm_disk_thin" {
    type        = bool
    description = "Indicates if the system disk should be thin provisioned"
}
variable "vm_cdrom_type" {
    type        = string
    description = "The type of CDROM device that should be configured on the VM"
}

# Provisioner Settings
variable "script_files" {
    type        = list(string)
    description = "A list of scripts defined using relative paths that will be executed against the VM"
}
variable "inline_cmds" {
    type        = list(string)
    description = "A list of commands that will be executed against the VM"
}

# Build Settings
variable "build_repo" {
    type        = string
    description = "The source control repository used to build the templates"
    default     = "https://github.com/v12n-io/packer"
}
variable "build_branch" {
    type        = string
    description = "The source control repository branch used to build the templates"
    default     = "none"
}
variable "build_username" {
    type        = string
    description = "The guest OS username used to login"
    default     = "root"
    sensitive   = true
}
variable "build_password" {
    type        = string
    description = "The password for the guest OS username"
    sensitive   = true
}

# HTTP Settings
variable "http_directory" {
    type        = string
    description = "The directory used to serve HTTP content"
}
variable "http_port_min" {
    type        = number
    description = "The lower port number to be used for HTTP content"
}
variable "http_port_max" {
    type        = number
    description = "The upper port number to be used for HTTP content"
}

# Local Variables
locals { 
    build_version   = formatdate("YYMM", timestamp())
    build_date      = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}

# -------------------------------------------------------------------------- #
#                       Template Source Definitions                          #
# -------------------------------------------------------------------------- #
## Photon 4 Server
source "vsphere-iso" "photon4" {
    # vCenter
    vcenter_server              = var.vcenter_server
    username                    = var.vcenter_username
    password                    = var.vcenter_password
    insecure_connection         = true
    datacenter                  = var.vcenter_datacenter
    cluster                     = var.vcenter_cluster
    folder                      = "Templates/${ var.os_family }/${ var.os_version }"
    datastore                   = var.vcenter_datastore
    remove_cdrom                = false
    convert_to_template         = true

    # Virtual Machine
    guest_os_type               = var.vm_os_type
    vm_name                     = "photon4-${ var.build_branch }-${ local.build_version }"
    notes                       = "VER: ${ local.build_version } (${ local.build_date })\nSRC: ${ var.build_repo } (${ var.build_branch })\nOS: Photon 4 Server\nISO: ${ var.os_iso_file }"
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_sockets
    cpu_cores                   = var.vm_cpu_cores
    RAM                         = var.vm_mem_size
    cdrom_type                  = var.vm_cdrom_type
    disk_controller_type        = var.vm_disk_controller
    storage {
        disk_size               = var.vm_disk_size
        disk_controller_index   = 0
        disk_thin_provisioned   = var.vm_disk_thin
    }
    network_adapters {
        network                 = var.vcenter_network
        network_card            = var.vm_nic_type
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.vcenter_iso_datastore }] ${ var.os_iso_path }/${ var.os_iso_file }" ]

    # Boot and Provisioner
    http_directory              = var.http_directory
    http_port_min               = var.http_port_min
    http_port_max               = var.http_port_max
    boot_order                  = "disk,cdrom"
    boot_command                = [ "<tab><wait>",
                                    " ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/photon4.json insecure_installation=1",
                                    "<enter>" ]
    ip_wait_timeout             = "20m"
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    shutdown_command            = "shutdown -P now"
    shutdown_timeout            = "15m"
}

# -------------------------------------------------------------------------- #
#                             Build Management                               #
# -------------------------------------------------------------------------- #
build {
    # Build sources
    sources                 = [ "source.vsphere-iso.photon4" ]
    
    /*# Shell Provisioner to execute commands 
    provisioner "shell" {
        inline              = var.inline_cmds
    }*/
    
    # Shell Provisioner to execute scripts 
    provisioner "shell" {
        scripts             = var.script_files
    }
}