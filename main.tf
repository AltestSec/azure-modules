# Main Terraform Configuration - Orchestrator
# This file serves as the main orchestrator for different deployment components
# Use feature flags to control which components to deploy

# Terraform configuration
#terraform {
#  required_version = ">= 1.0"
#  required_providers {
#    azurerm = {
#      source  = "hashicorp/azurerm"
#      version = "~> 3.0"
#    }
#  }
  
#  backend "azurerm" {
    # Backend configuration will be provided via init command
#  }
#}

# Configure the Microsoft Azure Provider
#provider "azurerm" {
#  features {
#    resource_group {
#      prevent_deletion_if_contains_resources = false
#    }
#    key_vault {
#      purge_soft_delete_on_destroy    = true
#      recover_soft_deleted_key_vaults = true
#    }
#  }
#}

# Feature flags to control deployment components
#variable "deploy_infrastructure" {
#  description = "Deploy basic infrastructure (RG, VNet, Subnets)"
#  type        = bool
#  default     = false
#}

#variable "deploy_vms" {
#  description = "Deploy VM resources"
#  type        = bool
#  default     = false
#}

#variable "deploy_avd" {
#  description = "Deploy AVD resources"
#  type        = bool
#  default     = false
#}

#variable "deploy_service_bus" {
#  description = "Deploy Service Bus resources"
#  type        = bool
#  default     = false
#}

# Infrastructure Module (conditional)
module "infrastructure" {
  count  = var.deploy_infrastructure ? 1 : 0
  source = "./modules/infrastructure"

  resource_group_name    = local.resource_group_name
  location              = var.location
  environment           = var.environment
  create_resource_group = var.create_resource_group
  resource_prefix       = var.resource_prefix
  common_tags           = local.common_tags
}

# VM Resources Module (conditional)
module "vm_resources" {
  count  = var.deploy_vms ? 1 : 0
  source = "./modules/vm-resources"

  resource_group_name    = local.resource_group_name
  location              = var.location
  environment           = var.environment
  pool_type             = var.pool_type
  vm_count              = var.vm_count
  vm_size               = var.vm_size
  admin_ssh_public_key  = var.admin_ssh_public_key
  auto_shutdown_enabled = var.auto_shutdown_enabled
  work_hours_end        = var.work_hours_end
  timezone              = var.timezone
  resource_prefix       = var.resource_prefix
  common_tags           = local.common_tags

  depends_on = [module.infrastructure]
}

# AVD Resources Module (conditional)
module "avd_resources" {
  count  = var.deploy_avd ? 1 : 0
  source = "./modules/avd"

  resource_group_name = local.resource_group_name
  location           = var.location
  environment        = var.environment
  resource_prefix    = var.resource_prefix
  common_tags        = local.common_tags

  depends_on = [module.infrastructure]
}

# Service Bus Module (conditional)
module "service_bus" {
  count  = var.deploy_service_bus ? 1 : 0
  source = "./modules/sbus"

  resource_group_name = local.resource_group_name
  location           = var.location
  environment        = var.environment
  resource_prefix    = var.resource_prefix
  common_tags        = local.common_tags

  depends_on = [module.infrastructure]
}