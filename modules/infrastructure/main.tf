# Infrastructure Module - Basic Azure Infrastructure
# This module creates the foundational infrastructure components

# Resource Group (conditional creation)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.common_tags, {
    Component = "Infrastructure"
    Purpose   = "Foundation"
  })
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
  name                = "${var.resource_prefix}-vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = merge(var.common_tags, {
    Component = "Infrastructure"
    Purpose   = "Networking"
  })
}

# Subnet for VMs
resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.resource_prefix}-subnet-vms-${var.environment}"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for AVD
resource "azurerm_subnet" "avd_subnet" {
  name                 = "${var.resource_prefix}-subnet-avd-${var.environment}"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet for other services
resource "azurerm_subnet" "services_subnet" {
  name                 = "${var.resource_prefix}-subnet-services-${var.environment}"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}