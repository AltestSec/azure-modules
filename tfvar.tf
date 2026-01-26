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

variable "auto_shutdown_enabled" {
  description = "Enable automatic shutdown for VMs"
  type        = bool
  default     = true
}

variable "work_hours_start" {
  description = "Work hours start time (24h format)"
  type        = string
  default     = "09:00"
}

variable "work_hours_end" {
  description = "Work hours end time (24h format)"
  type        = string
  default     = "18:00"
}

variable "timezone" {
  description = "Timezone for scheduling"
  type        = string
  default     = "Central European Standard Time"
}

# AVD-specific variables
variable "dev_vm_size" {
  description = "VM size for development session hosts"
  type        = string
  default     = "Standard_B2als_v2"  # 2 vCPU, 4 GB RAM, AMD EPYC-based, burstable
  
  validation {
    condition = can(regex("^Standard_", var.dev_vm_size))
    error_message = "VM size must be a valid Azure VM size starting with 'Standard_'."
  }
}

variable "mgmt_vm_size" {
  description = "VM size for management session hosts"
  type        = string
  default     = "Standard_B2als_v2"  # 2 vCPU, 4 GB RAM, AMD EPYC-based, burstable
  
  validation {
    condition = can(regex("^Standard_", var.mgmt_vm_size))
    error_message = "VM size must be a valid Azure VM size starting with 'Standard_'."
  }
}

variable "primary_location" {
  description = "Primary Azure region for EU resources"
  type        = string
  default     = "West Europe"
  
  validation {
    condition = contains([
      "West Europe", "North Europe", "UK South", "UK West",
      "France Central", "Germany West Central", "Switzerland North"
    ], var.primary_location)
    error_message = "Primary location must be a valid European Azure region."
  }
}

variable "secondary_location" {
  description = "Secondary Azure region for US resources"
  type        = string
  default     = "East US"
  
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US"
    ], var.secondary_location)
    error_message = "Secondary location must be a valid US Azure region."
  }
}