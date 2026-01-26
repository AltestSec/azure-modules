# AVD Session Hosts Module
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Data source for custom image
data "azurerm_shared_image" "custom" {
  count               = var.use_custom_image ? 1 : 0
  name                = var.custom_image_name
  gallery_name        = var.shared_image_gallery_name
  resource_group_name = var.shared_image_gallery_rg
}

# Network Interface for Session Hosts
resource "azurerm_network_interface" "session_host" {
  count               = var.session_host_count
  name                = "nic-avd-${var.pool_name}-${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Windows Virtual Machines for Session Hosts
resource "azurerm_windows_virtual_machine" "session_host" {
  count               = var.session_host_count
  name                = "avd-${var.pool_name}-${format("%02d", count.index + 1)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.session_host[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # Use custom image if specified, otherwise use marketplace image
  dynamic "source_image_reference" {
    for_each = var.use_custom_image ? [] : [1]
    content {
      publisher = var.vm_image_publisher
      offer     = var.vm_image_offer
      sku       = var.vm_image_sku
      version   = var.vm_image_version
    }
  }

  source_image_id = var.use_custom_image ? data.azurerm_shared_image.custom[0].id : null

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    PoolName = var.pool_name
    PoolType = var.pool_type
  })

  lifecycle {
    ignore_changes = [
      admin_password,
    ]
  }
}

# Domain Join Extension (if domain join is enabled)
resource "azurerm_virtual_machine_extension" "domain_join" {
  count                      = var.domain_join_enabled ? var.session_host_count : 0
  name                       = "DomainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = var.domain_ou_path
    User    = var.domain_join_username
    Restart = "true"
    Options = "3"
  })

  protected_settings = jsonencode({
    Password = var.domain_join_password
  })

  depends_on = [azurerm_windows_virtual_machine.session_host]
}

# AVD Agent Extension
resource "azurerm_virtual_machine_extension" "avd_agent" {
  count                      = var.session_host_count
  name                       = "AVDAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_windows_virtual_machine.session_host
  ]
}

# PowerShell DSC Extension for AVD Configuration
resource "azurerm_virtual_machine_extension" "avd_dsc" {
  count                      = var.session_host_count
  name                       = "AVD-DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName          = var.host_pool_name
      registrationInfoToken = var.host_pool_token
      aadJoin              = var.aad_join
      UseAgentDownloadEndpoint = true
      aadJoinPreview       = false
      mdmId                = ""
      sessionHostConfigurationLastUpdateTime = ""
    }
  })

  depends_on = [
    azurerm_virtual_machine_extension.avd_agent,
    azurerm_windows_virtual_machine.session_host
  ]
}

# Auto-shutdown schedule for Session Hosts
resource "azurerm_dev_test_global_vm_shutdown_schedule" "session_host" {
  count              = var.auto_shutdown_enabled ? var.session_host_count : 0
  virtual_machine_id = azurerm_windows_virtual_machine.session_host[count.index].id
  location           = var.location
  enabled            = true

  daily_recurrence_time = var.shutdown_time
  timezone              = var.timezone

  notification_settings {
    enabled         = true
    time_in_minutes = 30
    webhook_url     = var.shutdown_notification_webhook
    email           = var.shutdown_notification_email
  }

  tags = var.tags
}