terraform {
  required_version = ">=1.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

locals {
  env = terraform.workspace == "default" ? "dev" : terraform.workspace
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.this.name
}

data "azurerm_subnet" "vm" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

data "azurerm_ssh_public_key" "this" {
  name                = var.ssh_public_key_name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_public_ip" "tor_proxy_cluster_vm" {
  name                = "tor-proxy-cluster-public-ip-${local.env}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "tor_proxy_cluster_vm" {
  name                = "tor-proxy-cluster-nic-${local.env}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  ip_configuration {
    name                          = "tor-proxy-cluster-nic-ipconfig-${local.env}"
    subnet_id                     = data.azurerm_subnet.vm.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ip
    public_ip_address_id          = azurerm_public_ip.tor_proxy_cluster_vm.id
  }
}

resource "azurerm_network_security_group" "ssh_only" {
  name                = "ssh-only-nsg"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
}

resource "azurerm_network_security_rule" "allow_inbound_ssh" {
  name                        = "AllowSSHInbound"
  resource_group_name         = data.azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.ssh_only.name
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = 22
  priority                    = 100
}

resource "azurerm_network_interface_security_group_association" "tor_proxy_cluster_vm" {
  network_interface_id      = azurerm_network_interface.tor_proxy_cluster_vm.id
  network_security_group_id = azurerm_network_security_group.ssh_only.id
}

resource "azurerm_linux_virtual_machine" "tor_proxy_cluster_vm" {
  name                = "tor-proxy-cluster-vm-${local.env}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_B2s"
  admin_username      = "admin"
  network_interface_ids = [
    azurerm_network_interface.tor_proxy_cluster_vm.id
  ]

  admin_ssh_key {
    username   = "admin"
    public_key = data.azurerm_ssh_public_key.this.public_key
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}