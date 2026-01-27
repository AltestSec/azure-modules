# Variables
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-playground"
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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

variable "pool_type" {
  description = "Type of pool for VMs (web, api, worker)"
  type        = string
  default     = "web"
  
  validation {
    condition     = contains(["web", "api", "worker"], var.pool_type)
    error_message = "Pool type must be one of: web, api, worker."
  }
}

variable "timezone" {
  description = "Timezone for scheduling"
  type        = string
  default     = "Central European Standard Time"
}

variable "work_hours_end" {
  description = "Work hours end"
  type        = string
  default     = "Central European Standard Time"
}