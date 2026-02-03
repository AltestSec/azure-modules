# VM Resources Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "pool_type" {
  description = "Type of pool for VMs (web, api, worker)"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["web", "api", "worker"], var.pool_type)
    error_message = "Pool type must be one of: web, api, worker."
  }
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2als_v2"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM admin user"
  type        = string
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for VMs"
  type        = bool
  default     = true
}

variable "work_hours_end" {
  description = "Work hours end time (24-hour format, e.g., 1900)"
  type        = string
  default     = "1900"
}

variable "timezone" {
  description = "Timezone for scheduling"
  type        = string
  default     = "Central European Standard Time"
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}