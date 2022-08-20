provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "centos" {
  name          = "/${var.datacenter}/vm/${var.centos_name}"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "Satellite" {
  name             = "Satellite"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 4
  memory   = 24576

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = -1

  disk {
    label            = "disk0"
    thin_provisioned = true
    size             = 18
  }

  disk {
    label            = "disk1"
    thin_provisioned = true
    size             = 400
    unit_number = 1
  }


  guest_id = "centos8_64Guest"

  clone {
    template_uuid = data.vsphere_virtual_machine.centos.id
    customize {
      linux_options {
        host_name = "satellite"
        domain    = "kazmi.lab"
      }
      network_interface {
        ipv4_address = "10.0.0.100"
        ipv4_netmask = 24
      }
      ipv4_gateway = "10.0.0.1"
      dns_server_list = ["10.0.0.1"]
    }
  }
}

output "vm_ip" {
  value = vsphere_virtual_machine.Satellite.guest_ip_addresses
}
# use "terrafrom refresh" command to view the the output