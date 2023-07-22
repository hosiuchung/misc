variable "resource_group_name" {
  type     = string
  nullable = false
}

variable "vnet_name" {
  type     = string
  nullable = false
}

variable "subnet_name" {
  type     = string
  nullable = false
}

variable "vm_subnet_private_ip" {
  type     = string
  nullable = false
}

variable "ssh_public_key_name" {
  type     = string
  nullable = false
}