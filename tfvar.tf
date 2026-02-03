# Variables
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources (e.g., omerzlikin)"
  type        = string
  default     = "omerzlikin"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
  default     = "northeurope"
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

variable "admin_ssh_public_key" {
  description = "SSH public key for VM admin user"
  type        = string
  default     = ""
}

variable "work_hours_end" {
  description = "Work hours end"
  type        = string
  default     = "1900"
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for VMs"
  type        = bool
  default     = true
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing"
  type        = bool
  default     = false
}

variable "due_date" {
  description = "Due date for resources (YYYY-MM-DD)"
  type        = string
  default     = ""
}

# Feature flags for modular deployment
variable "deploy_infrastructure" {
  description = "Deploy basic infrastructure (RG, VNet, Subnets)"
  type        = bool
  default     = false
}

variable "deploy_vms" {
  description = "Deploy VM resources"
  type        = bool
  default     = false
}

variable "deploy_avd" {
  description = "Deploy AVD resources"
  type        = bool
  default     = false
}

variable "deploy_service_bus" {
  description = "Deploy Service Bus resources"
  type        = bool
  default     = false
}

# AVD-specific variables (when needed)
variable "avd_admin_password" {
  description = "Admin password for AVD session hosts"
  type        = string
  default     = ""
  sensitive   = true
}

# Local values for consistent naming and tagging
locals {
  # Resource naming with prefix
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.resource_prefix}-rg-${var.environment}"
  
  # Calculate due date (current date + 5 days if not provided)
  due_date = var.due_date != "" ? var.due_date : formatdate("YYYY-MM-DD", timeadd(timestamp(), "120h"))
  
  # Common tags for all resources
  common_tags = {
    owner       = var.resource_prefix
    dueDate     = local.due_date
    environment = var.environment
    managedBy   = "terraform"
    createdDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Backend configuration values (for reference) - CONSOLIDATED APPROACH
  backend_config = {
    resource_group_name  = "${var.resource_prefix}-tfstate-rg"        # ONE shared RG for all backends
    storage_account_name = "${var.resource_prefix}tfstatestorage"     # ONE shared storage account
    container_name       = "tfstate-${var.environment}"              # ONE shared container per environment
    # Component-specific keys:
    # infrastructure.tfstate, vm-resources.tfstate, avd.tfstate, service-bus.tfstate
  }
}