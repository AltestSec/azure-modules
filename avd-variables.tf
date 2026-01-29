# AVD Infrastructure Variables

# General Configuration
variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "IT-Infrastructure"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "AVD-Team"
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed to access resources"
  type        = string
  default     = "0.0.0.0/0"
}

# Pool Size Configuration
variable "dev_pool_size_eu" {
  description = "Number of session hosts in EU development pool"
  type        = number
  default     = 4
  
  validation {
    condition     = var.dev_pool_size_eu >= 1 && var.dev_pool_size_eu <= 20
    error_message = "Development pool size must be between 1 and 20."
  }
}

variable "dev_pool_size_us" {
  description = "Number of session hosts in US development pool"
  type        = number
  default     = 6
  
  validation {
    condition     = var.dev_pool_size_us >= 1 && var.dev_pool_size_us <= 20
    error_message = "Development pool size must be between 1 and 20."
  }
}

variable "mgmt_pool_size_us" {
  description = "Number of session hosts in US management pool"
  type        = number
  default     = 3
  
  validation {
    condition     = var.mgmt_pool_size_us >= 1 && var.mgmt_pool_size_us <= 10
    error_message = "Management pool size must be between 1 and 10."
  }
}

# AVD Authentication Configuration
variable "avd_admin_username" {
  description = "Admin username for AVD session hosts"
  type        = string
  default     = "avdadmin"
}

variable "avd_admin_password" {
  description = "Admin password for AVD session hosts"
  type        = string
  sensitive   = true
}

variable "use_aad_join" {
  description = "Use Azure AD join instead of domain join"
  type        = bool
  default     = true
}

# Domain Join Configuration (Alternative to AAD Join)
variable "domain_join_enabled" {
  description = "Enable domain join for session hosts"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for domain join"
  type        = string
  default     = ""
}

variable "domain_join_username" {
  description = "Username for domain join"
  type        = string
  default     = ""
}

variable "domain_join_password" {
  description = "Password for domain join"
  type        = string
  default     = ""
  sensitive   = true
}

# Auto-shutdown Configuration
#variable "auto_shutdown_enabled" {
#  description = "Enable auto-shutdown for session hosts"
#  type        = bool
#  default     = true
#}

# Image Building Configuration
variable "enable_image_building" {
  description = "Enable automated image building pipeline"
  type        = bool
  default     = true
}

variable "image_build_schedule" {
  description = "Cron schedule for image building"
  type        = string
  default     = "0 2 * * 0"  # Every Sunday at 2 AM
}

# Security Configuration
variable "enable_security_scanning" {
  description = "Enable security scanning for images and infrastructure"
  type        = bool
  default     = true
}

variable "enable_compliance_monitoring" {
  description = "Enable compliance monitoring"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_advanced_monitoring" {
  description = "Enable advanced monitoring and alerting"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 90
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable backup for session hosts"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# VM Size Configuration
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

# Location Configuration
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
