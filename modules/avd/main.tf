# AVD Module Wrapper
# This module wraps the existing AVD modules for deployment

# Data source for existing resource group
data "azurerm_resource_group" "avd_rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "avd_subnet" {
  name                 = "subnet-avd"
  virtual_network_name = "vnet-${var.environment}"
  resource_group_name  = var.resource_group_name
}

# Include the existing AVD main configuration
# This will reference the existing avd-main.tf content
# For now, we'll create a placeholder that can be expanded

locals {
  common_tags = {
    Environment = var.environment
    Component   = "AVD"
    ManagedBy   = "Terraform"
  }
}

# Placeholder for AVD resources
# The actual AVD resources from avd-main.tf should be moved here
# or referenced as sub-modules

# Example AVD Host Pool (simplified)
resource "azurerm_virtual_desktop_host_pool" "main" {
  location            = data.azurerm_resource_group.avd_rg.location
  resource_group_name = data.azurerm_resource_group.avd_rg.name

  name                     = "avd-hostpool-${var.environment}"
  friendly_name            = "AVD Host Pool ${title(var.environment)}"
  validate_environment     = true
  start_vm_on_connect      = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  description              = "AVD Host Pool for ${var.environment} environment"
  type                     = "Pooled"
  maximum_sessions_allowed = 4
  load_balancer_type       = "BreadthFirst"

  tags = local.common_tags
}

# AVD Workspace
resource "azurerm_virtual_desktop_workspace" "main" {
  name                = "avd-workspace-${var.environment}"
  location            = data.azurerm_resource_group.avd_rg.location
  resource_group_name = data.azurerm_resource_group.avd_rg.name

  friendly_name = "AVD Workspace ${title(var.environment)}"
  description   = "AVD Workspace for ${var.environment} environment"

  tags = local.common_tags
}

# AVD Application Group
resource "azurerm_virtual_desktop_application_group" "main" {
  name                = "avd-appgroup-${var.environment}"
  location            = data.azurerm_resource_group.avd_rg.location
  resource_group_name = data.azurerm_resource_group.avd_rg.name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.main.id
  friendly_name = "AVD Application Group ${title(var.environment)}"
  description   = "AVD Application Group for ${var.environment} environment"

  tags = local.common_tags
}

# Associate Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "main" {
  workspace_id         = azurerm_virtual_desktop_workspace.main.id
  application_group_id = azurerm_virtual_desktop_application_group.main.id
}