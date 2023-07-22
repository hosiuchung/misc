terraform {
  backend "azurerm" {
    resource_group_name  = "rg"
    storage_account_name = "storage-account"
    container_name       = "tfstate"
    key                  = "tor-proxy-cluster/terraform.tfstate"
  }
}