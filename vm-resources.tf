# VM-Only Resources
# This file contains only VM-related resources

# Data sources for existing infrastructure
data "azurerm_resource_group" "vm_rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "vm_subnet" {
  name                 = "subnet-vms"
  virtual_network_name = "vnet-${var.environment}"
  resource_group_name  = var.resource_group_name
}

# Network Security Group for VMs
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-${var.pool_type}"
  location            = data.azurerm_resource_group.vm_rg.location
  resource_group_name = data.azurerm_resource_group.vm_rg.name

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
    PoolType    = var.pool_type
  }
}

# Public IPs for VMs
resource "azurerm_public_ip" "vm_pip" {
  count               = var.vm_count
  name                = "pip-${var.pool_type}-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.vm_rg.name
  location            = data.azurerm_resource_group.vm_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    PoolType    = var.pool_type
  }
}

# Network Interfaces for VMs
resource "azurerm_network_interface" "vm_nic" {
  count               = var.vm_count
  name                = "nic-${var.pool_type}-${count.index + 1}"
  location            = data.azurerm_resource_group.vm_rg.location
  resource_group_name = data.azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip[count.index].id
  }

  tags = {
    Environment = var.environment
    PoolType    = var.pool_type
  }
}

# Associate NSG to Network Interface
resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "vm-${var.pool_type}-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.vm_rg.name
  location            = data.azurerm_resource_group.vm_rg.location
  size                = var.vm_size
  admin_username      = "adminuser"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id,
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
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_shutdown" {
  count              = var.auto_shutdown_enabled ? var.vm_count : 0
  virtual_machine_id = azurerm_linux_virtual_machine.vm[count.index].id
  location           = data.azurerm_resource_group.vm_rg.location
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