# Shared Image Gallery Module for Custom AVD Images
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Azure Container Registry for storing custom images
resource "azurerm_container_registry" "main" {
  name                = "acr${var.environment}${var.location_short}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  #sku                 = var.acr_sku
  sku                 = "Standard"
  admin_enabled       = true

  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  network_rule_set {
    default_action = "Deny"

    ip_rule {
      action   = "Allow"
      ip_range = var.allowed_ip_ranges
    }

    virtual_network {
      action    = "Allow"
      subnet_id = var.subnet_id
    }
  }

  retention_policy {
    days    = var.image_retention_days
    enabled = true
  }

  trust_policy {
    enabled = true
  }

  tags = var.tags
}

# Shared Image Gallery
resource "azurerm_shared_image_gallery" "main" {
  name                = "sig_avd_${var.environment}_${var.location_short}"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Shared Image Gallery for AVD custom images - ${var.environment}"

  tags = var.tags
}

# Image Definition for Development/DevOps Image
resource "azurerm_shared_image" "dev_image" {
  name                = "avd-dev-image"
  gallery_name        = azurerm_shared_image_gallery.main.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  hyper_v_generation  = "V2"
  architecture        = "x64"

  description = "Custom AVD image for developers, DevOps, and QA teams with development tools"

  identifier {
    publisher = "CustomAVD"
    offer     = "DeveloperDesktop"
    sku       = "dev-tools-v1"
  }

  purchase_plan {
    name      = "dev-tools-v1"
    publisher = "CustomAVD"
    product   = "DeveloperDesktop"
  }

  tags = merge(var.tags, {
    ImageType = "Development"
    Version   = "1.0"
  })
}

# Image Definition for Management/BA Image
resource "azurerm_shared_image" "mgmt_image" {
  name                = "avd-mgmt-image"
  gallery_name        = azurerm_shared_image_gallery.main.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  hyper_v_generation  = "V2"
  architecture        = "x64"

  description = "Custom AVD image for management and business analysts with office applications"

  identifier {
    publisher = "CustomAVD"
    offer     = "ManagementDesktop"
    sku       = "office-tools-v1"
  }

  purchase_plan {
    name      = "office-tools-v1"
    publisher = "CustomAVD"
    product   = "ManagementDesktop"
  }

  tags = merge(var.tags, {
    ImageType = "Management"
    Version   = "1.0"
  })
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Private Endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-acr-${var.environment}"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-group-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = var.tags
}

# Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "pdz-link-acr-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false

  tags = var.tags
}