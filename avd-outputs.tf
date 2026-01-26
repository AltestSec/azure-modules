# AVD Infrastructure Outputs

# Workspace Information
output "avd_workspace_eu_id" {
  description = "ID of the AVD workspace in EU"
  value       = module.avd_workspace_eu.workspace_id
}

output "avd_workspace_us_id" {
  description = "ID of the AVD workspace in US"
  value       = module.avd_workspace_us.workspace_id
}

output "avd_workspace_eu_name" {
  description = "Name of the AVD workspace in EU"
  value       = module.avd_workspace_eu.workspace_name
}

output "avd_workspace_us_name" {
  description = "Name of the AVD workspace in US"
  value       = module.avd_workspace_us.workspace_name
}

# Host Pool Information
output "dev_hostpool_eu_id" {
  description = "ID of the development host pool in EU"
  value       = module.avd_hostpool_dev_eu.host_pool_id
}

output "dev_hostpool_us_id" {
  description = "ID of the development host pool in US"
  value       = module.avd_hostpool_dev_us.host_pool_id
}

output "mgmt_hostpool_us_id" {
  description = "ID of the management host pool in US"
  value       = module.avd_hostpool_mgmt_us.host_pool_id
}

# Session Host Information
output "dev_session_hosts_eu" {
  description = "Development session hosts in EU"
  value = {
    names       = module.avd_sessionhosts_dev_eu.session_host_names
    private_ips = module.avd_sessionhosts_dev_eu.session_host_private_ips
    count       = length(module.avd_sessionhosts_dev_eu.session_host_names)
  }
}

output "dev_session_hosts_us" {
  description = "Development session hosts in US"
  value = {
    names       = module.avd_sessionhosts_dev_us.session_host_names
    private_ips = module.avd_sessionhosts_dev_us.session_host_private_ips
    count       = length(module.avd_sessionhosts_dev_us.session_host_names)
  }
}

output "mgmt_session_hosts_us" {
  description = "Management session hosts in US"
  value = {
    names       = module.avd_sessionhosts_mgmt_us.session_host_names
    private_ips = module.avd_sessionhosts_mgmt_us.session_host_private_ips
    count       = length(module.avd_sessionhosts_mgmt_us.session_host_names)
  }
}

# Image Gallery Information
output "shared_image_gallery_name" {
  description = "Name of the Shared Image Gallery"
  value       = module.shared_image_gallery.shared_image_gallery_name
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = module.shared_image_gallery.container_registry_name
}

output "container_registry_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = module.shared_image_gallery.container_registry_login_server
}

# Custom Images
output "dev_image_name" {
  description = "Name of the development custom image"
  value       = module.shared_image_gallery.dev_image_name
}

output "mgmt_image_name" {
  description = "Name of the management custom image"
  value       = module.shared_image_gallery.mgmt_image_name
}

# Network Information
output "vnet_eu_id" {
  description = "ID of the EU virtual network"
  value       = azurerm_virtual_network.avd_eu.id
}

output "vnet_us_id" {
  description = "ID of the US virtual network"
  value       = azurerm_virtual_network.avd_us.id
}

# Resource Group Information
output "resource_groups" {
  description = "Resource groups created for AVD"
  value = {
    eu = {
      name     = azurerm_resource_group.avd_eu.name
      location = azurerm_resource_group.avd_eu.location
    }
    us = {
      name     = azurerm_resource_group.avd_us.name
      location = azurerm_resource_group.avd_us.location
    }
  }
}

# Summary Information
output "avd_deployment_summary" {
  description = "Summary of AVD deployment"
  value = {
    total_session_hosts = var.dev_pool_size_eu + var.dev_pool_size_us + var.mgmt_pool_size_us
    pools = {
      dev_eu = {
        location     = var.primary_location
        vm_size      = var.dev_vm_size
        host_count   = var.dev_pool_size_eu
        image_type   = "Development"
      }
      dev_us = {
        location     = var.secondary_location
        vm_size      = var.dev_vm_size
        host_count   = var.dev_pool_size_us
        image_type   = "Development"
      }
      mgmt_us = {
        location     = var.secondary_location
        vm_size      = var.mgmt_vm_size
        host_count   = var.mgmt_pool_size_us
        image_type   = "Management"
      }
    }
    features = {
      auto_shutdown        = var.auto_shutdown_enabled
      aad_join            = var.use_aad_join
      custom_images       = true
      security_scanning   = var.enable_security_scanning
      advanced_monitoring = var.enable_advanced_monitoring
    }
  }
}