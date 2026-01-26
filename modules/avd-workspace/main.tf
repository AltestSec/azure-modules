# AVD Workspace Module
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Log Analytics Workspace for AVD
resource "azurerm_log_analytics_workspace" "avd" {
  name                = "law-avd-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# AVD Workspace
resource "azurerm_virtual_desktop_workspace" "main" {
  name                = "avd-workspace-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "AVD Workspace ${var.environment} ${var.location}"
  description         = "Azure Virtual Desktop workspace for ${var.environment} environment"

  tags = var.tags
}

# Diagnostic Settings for AVD Workspace
resource "azurerm_monitor_diagnostic_setting" "avd_workspace" {
  name                       = "diag-avd-workspace"
  target_resource_id         = azurerm_virtual_desktop_workspace.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd.id

  enabled_log {
    category = "Checkpoint"
  }

  enabled_log {
    category = "Error"
  }

  enabled_log {
    category = "Management"
  }

  enabled_log {
    category = "Feed"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}