# Basic Infrastructure - Resource Group, VNet, Subnets
# This file contains shared infrastructure components

# Resource Group (conditional creation)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Data source for existing resource group
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Local to get the correct resource group
locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.main[0] : data.azurerm_resource_group.existing[0]
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Subnet for VMs
resource "azurerm_subnet" "vm_subnet" {
  name                 = "subnet-vms"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for other services
resource "azurerm_subnet" "services_subnet" {
  name                 = "subnet-services"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}