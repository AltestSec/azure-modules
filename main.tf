# Main Terraform Configuration
# This file includes all components for full deployment

# Infrastructure Components
# Uncomment the line below to include infrastructure resources
# terraform {
#   source = "./infrastructure.tf"
# }

# VM Resources
# Uncomment the line below to include VM resources
# terraform {
#   source = "./vm-resources.tf"
# }

# Service Bus Resources  
# Uncomment the line below to include Service Bus resources
# terraform {
#   source = "./service-bus.tf"
# }

# AVD Resources
# Uncomment the line below to include AVD resources
# terraform {
#   source = "./avd-main.tf"
# }

# For now, include all components for backward compatibility
# You can comment out sections you don't want to deploy

# Basic Infrastructure (conditional)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.main[0] : data.azurerm_resource_group.existing[0]
}

# Virtual Network (only if not using separate infrastructure deployment)
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = {
    Environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "internal" {
  name                 = "subnet-${var.pool_type}"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.pool_type}"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
  }
}

# Public IPs
resource "azurerm_public_ip" "main" {
  count               = var.vm_count
  name                = "pip-${var.pool_type}-${count.index + 1}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    PoolType    = var.pool_type
  }
}

# Network Interfaces
resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "nic-${var.pool_type}-${count.index + 1}"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main[count.index].id
  }

  tags = {
    Environment = var.environment
    PoolType    = var.pool_type
  }
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.vm_count
  name                = "vm-${var.pool_type}-${count.index + 1}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  size                = var.vm_size
  admin_username      = "adminuser"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment  = var.environment
    PoolType     = var.pool_type
    AutoShutdown = var.auto_shutdown_enabled
  }
}

# Auto-shutdown schedule for VMs
resource "azurerm_dev_test_global_vm_shutdown_schedule" "main" {
  count              = var.auto_shutdown_enabled ? var.vm_count : 0
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  location           = local.resource_group.location
  enabled            = true

  daily_recurrence_time = var.work_hours_end
  timezone              = var.timezone

  notification_settings {
    enabled = false
  }

  tags = {
    Environment = var.environment
  }
}

# Service Bus Module (optional - comment out if not needed)
module "sbus" {
  source = "./modules/sbus"

  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  environment         = var.environment
}