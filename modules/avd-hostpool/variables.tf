# AVD Host Pool Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "location_short" {
  description = "Short name for the location"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "pool_name" {
  description = "Name of the host pool"
  type        = string
}

variable "pool_display_name" {
  description = "Display name of the host pool"
  type        = string
}

variable "workspace_id" {
  description = "ID of the AVD workspace"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "host_pool_type" {
  description = "Type of host pool (Pooled or Personal)"
  type        = string
  default     = "Pooled"
  
  validation {
    condition     = contains(["Pooled", "Personal"], var.host_pool_type)
    error_message = "Host pool type must be either 'Pooled' or 'Personal'."
  }
}

variable "load_balancer_type" {
  description = "Load balancer type for the host pool"
  type        = string
  default     = "DepthFirst"
  
  validation {
    condition     = contains(["BreadthFirst", "DepthFirst"], var.load_balancer_type)
    error_message = "Load balancer type must be either 'BreadthFirst' or 'DepthFirst'."
  }
}

variable "application_group_type" {
  description = "Type of application group"
  type        = string
  default     = "Desktop"
  
  validation {
    condition     = contains(["Desktop", "RemoteApp"], var.application_group_type)
    error_message = "Application group type must be either 'Desktop' or 'RemoteApp'."
  }
}

variable "personal_desktop_assignment_type" {
  description = "Assignment type for personal desktops"
  type        = string
  default     = "Automatic"
  
  validation {
    condition     = contains(["Automatic", "Direct"], var.personal_desktop_assignment_type)
    error_message = "Personal desktop assignment type must be either 'Automatic' or 'Direct'."
  }
}

variable "maximum_sessions_allowed" {
  description = "Maximum sessions allowed per session host"
  type        = number
  default     = 10
}

variable "start_vm_on_connect" {
  description = "Enable start VM on connect"
  type        = bool
  default     = true
}

variable "custom_rdp_properties" {
  description = "Custom RDP properties"
  type        = string
  default     = "drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;use multimon:i:0"
}

variable "timezone" {
  description = "Timezone for scheduling"
  type        = string
  default     = "UTC"
}

variable "work_hours_start" {
  description = "Work hours start time"
  type        = string
  default     = "09:00"
}

variable "peak_hours_start" {
  description = "Peak hours start time"
  type        = string
  default     = "10:00"
}

variable "ramp_down_start" {
  description = "Ramp down start time"
  type        = string
  default     = "18:00"
}

variable "off_peak_start" {
  description = "Off peak start time"
  type        = string
  default     = "22:00"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}