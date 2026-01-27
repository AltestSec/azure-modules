# AVD Host Pool Module
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
  }
}

locals {
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
}

# AVD Host Pool
resource "azurerm_virtual_desktop_host_pool" "main" {
  name                = "avd-hp-${var.pool_name}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.host_pool_type
  load_balancer_type  = var.load_balancer_type
  friendly_name       = "${var.pool_display_name} - ${var.environment}"
  description         = "AVD Host Pool for ${var.pool_display_name} in ${var.environment}"
  
  validate_environment                 = true
  start_vm_on_connect                 = var.start_vm_on_connect
  custom_rdp_properties               = var.custom_rdp_properties
  maximum_sessions_allowed            = var.maximum_sessions_allowed
  personal_desktop_assignment_type    = var.host_pool_type == "Personal" ? var.personal_desktop_assignment_type : null

  scheduled_agent_updates {
    enabled                   = true
    timezone                  = var.timezone
    use_session_host_timezone = false

    schedule {
      day_of_week = "Saturday"
      hour_of_day = 2
    }
    schedule {
      day_of_week = "Sunday"
      hour_of_day = 2
    }
  }

  tags = var.tags
}

# Host Pool Registration Info (for session host registration)
resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.main.id
  expiration_date = timeadd(timestamp(), "48h")  # Token expires in 48 hours
}

# AVD Application Group
resource "azurerm_virtual_desktop_application_group" "main" {
  name                = "avd-ag-${var.pool_name}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.application_group_type
  host_pool_id        = azurerm_virtual_desktop_host_pool.main.id
  friendly_name       = "${var.pool_display_name} Apps - ${var.environment}"
  description         = "Application group for ${var.pool_display_name}"

  tags = var.tags
}

# Associate Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "main" {
  workspace_id         = var.workspace_id
  application_group_id = azurerm_virtual_desktop_application_group.main.id
}

# Scaling Plan for Pooled Host Pools
resource "azurerm_virtual_desktop_scaling_plan" "main" {
  count               = var.host_pool_type == "Pooled" ? 1 : 0
  name                = "avd-sp-${var.pool_name}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "Scaling Plan for ${var.pool_display_name}"
  description         = "Auto-scaling plan for ${var.pool_display_name}"
  time_zone           = var.timezone

  # Work hours schedule
  schedule {
    name                                 = "work_hours"
    days_of_week                        = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                  = var.work_hours_start
    ramp_up_load_balancing_algorithm    = "BreadthFirst"
    ramp_up_minimum_hosts_percent       = 20
    ramp_up_capacity_threshold_percent  = 60

    peak_start_time                     = var.peak_hours_start
    peak_load_balancing_algorithm       = "DepthFirst"

    ramp_down_start_time                = var.ramp_down_start
    ramp_down_load_balancing_algorithm  = "DepthFirst"
    ramp_down_minimum_hosts_percent     = 10
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users        = false
    ramp_down_stop_hosts_when           = "ZeroSessions"
    ramp_down_wait_time_minutes         = 30
    ramp_down_notification_message      = "You will be logged off in 30 min. Make sure to save your work."

    off_peak_start_time                 = var.off_peak_start
    off_peak_load_balancing_algorithm   = "DepthFirst"
  }

  # Weekend schedule
  schedule {
    name                                 = "weekend"
    days_of_week                        = ["Saturday", "Sunday"]
    ramp_up_start_time                  = "09:00"
    ramp_up_load_balancing_algorithm    = "DepthFirst"
    ramp_up_minimum_hosts_percent       = 0
    ramp_up_capacity_threshold_percent  = 90

    peak_start_time                     = "10:00"
    peak_load_balancing_algorithm       = "DepthFirst"

    ramp_down_start_time                = "18:00"
    ramp_down_load_balancing_algorithm  = "DepthFirst"
    ramp_down_minimum_hosts_percent     = 0
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users        = false
    ramp_down_stop_hosts_when           = "ZeroSessions"
    ramp_down_wait_time_minutes         = 15
    ramp_down_notification_message      = "Weekend session ending in 15 min."

    off_peak_start_time                 = "22:00"
    off_peak_load_balancing_algorithm   = "DepthFirst"
  }

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.main.id
    scaling_plan_enabled = true
  }

  tags = var.tags
}

# Diagnostic Settings for Host Pool
resource "azurerm_monitor_diagnostic_setting" "host_pool" {
  name                       = "diag-avd-hostpool-${var.pool_name}"
  target_resource_id         = azurerm_virtual_desktop_host_pool.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

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
    category = "Connection"
  }

  enabled_log {
    category = "HostRegistration"
  }

  enabled_log {
    category = "AgentHealthStatus"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}