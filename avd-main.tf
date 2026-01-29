# Main AVD Infrastructure Configuration
# This file orchestrates all AVD modules to create a complete multi-region, multi-pool AVD environment

locals {
  # Common tags for all resources
  common_tags = {
    Environment   = var.environment
    Project       = "AVD-Infrastructure"
    ManagedBy     = "Terraform"
    CostCenter    = var.cost_center
    Owner         = var.owner
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Location mappings
  locations = {
    primary = {
      name       = var.primary_location
      short_name = var.primary_location == "West Europe" ? "eu" : "primary"
      timezone   = var.primary_location == "West Europe" ? "Central European Standard Time" : "UTC"
    }
    secondary = {
      name       = var.secondary_location
      short_name = var.secondary_location == "East US" ? "us" : "secondary"
      timezone   = var.secondary_location == "East US" ? "Eastern Standard Time" : "UTC"
    }
  }

  # Pool configurations
  pool_configs = {
    dev_eu = {
      location              = var.primary_location
      location_short        = local.locations.primary.short_name
      pool_name            = "dev"
      pool_display_name    = "Development Pool ${upper(local.locations.primary.short_name)}"
      pool_type            = "development"
      vm_size              = var.dev_vm_size
      session_host_count   = var.dev_pool_size_eu
      host_pool_type       = "Pooled"
      max_sessions         = 4
      use_custom_image     = true
      custom_image_name    = "avd-dev-image"
      timezone             = local.locations.primary.timezone
      work_hours_start     = "09:00"
      peak_hours_start     = "10:00"
      ramp_down_start      = "18:00"
      off_peak_start       = "22:00"
      shutdown_time        = "19:00"
    }
    dev_us = {
      location              = var.secondary_location
      location_short        = local.locations.secondary.short_name
      pool_name            = "dev"
      pool_display_name    = "Development Pool ${upper(local.locations.secondary.short_name)}"
      pool_type            = "development"
      vm_size              = var.dev_vm_size
      session_host_count   = var.dev_pool_size_us
      host_pool_type       = "Pooled"
      max_sessions         = 4
      use_custom_image     = true
      custom_image_name    = "avd-dev-image"
      timezone             = local.locations.secondary.timezone
      work_hours_start     = "09:00"
      peak_hours_start     = "10:00"
      ramp_down_start      = "18:00"
      off_peak_start       = "22:00"
      shutdown_time        = "19:00"
    }
    mgmt_us = {
      location              = var.secondary_location
      location_short        = local.locations.secondary.short_name
      pool_name            = "mgmt"
      pool_display_name    = "Management Pool ${upper(local.locations.secondary.short_name)}"
      pool_type            = "management"
      vm_size              = var.mgmt_vm_size
      session_host_count   = var.mgmt_pool_size_us
      host_pool_type       = "Pooled"
      max_sessions         = 6
      use_custom_image     = true
      custom_image_name    = "avd-mgmt-image"
      timezone             = local.locations.secondary.timezone
      work_hours_start     = "08:00"
      peak_hours_start     = "09:00"
      ramp_down_start      = "17:00"
      off_peak_start       = "20:00"
      shutdown_time        = "18:00"
    }
  }
}

# Resource Groups for each region
resource "azurerm_resource_group" "avd_eu" {
  name     = "rg-avd-${var.environment}-${local.locations.primary.short_name}"
  location = var.primary_location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "avd_us" {
  name     = "rg-avd-${var.environment}-${local.locations.secondary.short_name}"
  location = var.secondary_location
  tags     = local.common_tags
}

# Virtual Networks for each region
resource "azurerm_virtual_network" "avd_eu" {
  name                = "vnet-avd-${var.environment}-${local.locations.primary.short_name}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.avd_eu.location
  resource_group_name = azurerm_resource_group.avd_eu.name
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "avd_us" {
  name                = "vnet-avd-${var.environment}-${local.locations.secondary.short_name}"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.avd_us.location
  resource_group_name = azurerm_resource_group.avd_us.name
  tags                = local.common_tags
}

# Subnets for AVD Session Hosts
resource "azurerm_subnet" "avd_hosts_eu" {
  name                 = "snet-avd-hosts-${local.locations.primary.short_name}"
  resource_group_name  = azurerm_resource_group.avd_eu.name
  virtual_network_name = azurerm_virtual_network.avd_eu.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "avd_hosts_us" {
  name                 = "snet-avd-hosts-${local.locations.secondary.short_name}"
  resource_group_name  = azurerm_resource_group.avd_us.name
  virtual_network_name = azurerm_virtual_network.avd_us.name
  address_prefixes     = ["10.2.1.0/24"]
}

# Subnets for Private Endpoints
resource "azurerm_subnet" "private_endpoints_eu" {
  name                 = "snet-private-endpoints-${local.locations.primary.short_name}"
  resource_group_name  = azurerm_resource_group.avd_eu.name
  virtual_network_name = azurerm_virtual_network.avd_eu.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "private_endpoints_us" {
  name                 = "snet-private-endpoints-${local.locations.secondary.short_name}"
  resource_group_name  = azurerm_resource_group.avd_us.name
  virtual_network_name = azurerm_virtual_network.avd_us.name
  address_prefixes     = ["10.2.2.0/24"]
}

# Network Security Groups
resource "azurerm_network_security_group" "avd_eu" {
  name                = "nsg-avd-${var.environment}-${local.locations.primary.short_name}"
  location            = azurerm_resource_group.avd_eu.location
  resource_group_name = azurerm_resource_group.avd_eu.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAVDTraffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "avd_us" {
  name                = "nsg-avd-${var.environment}-${local.locations.secondary.short_name}"
  location            = azurerm_resource_group.avd_us.location
  resource_group_name = azurerm_resource_group.avd_us.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAVDTraffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "avd_eu" {
  subnet_id                 = azurerm_subnet.avd_hosts_eu.id
  network_security_group_id = azurerm_network_security_group.avd_eu.id
}

resource "azurerm_subnet_network_security_group_association" "avd_us" {
  subnet_id                 = azurerm_subnet.avd_hosts_us.id
  network_security_group_id = azurerm_network_security_group.avd_us.id
}

# Shared Image Gallery (in primary region)
module "shared_image_gallery" {
  source = "./modules/shared-image-gallery"

  resource_group_name         = azurerm_resource_group.avd_eu.name
  location                   = azurerm_resource_group.avd_eu.location
  location_short             = local.locations.primary.short_name
  environment                = var.environment
  subnet_id                  = azurerm_subnet.avd_hosts_eu.id
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints_eu.id
  virtual_network_id         = azurerm_virtual_network.avd_eu.id
  acr_sku                    = "Standard"
  image_retention_days       = 60
  allowed_ip_ranges          = var.allowed_ip_ranges
  tags                       = local.common_tags
}

# AVD Workspaces
module "avd_workspace_eu" {
  source = "./modules/avd-workspace"

  resource_group_name = azurerm_resource_group.avd_eu.name
  location           = azurerm_resource_group.avd_eu.location
  location_short     = local.locations.primary.short_name
  environment        = var.environment
  tags               = local.common_tags
}

module "avd_workspace_us" {
  source = "./modules/avd-workspace"

  resource_group_name = azurerm_resource_group.avd_us.name
  location           = azurerm_resource_group.avd_us.location
  location_short     = local.locations.secondary.short_name
  environment        = var.environment
  tags               = local.common_tags
}

# AVD Host Pools
module "avd_hostpool_dev_eu" {
  source = "./modules/avd-hostpool"

  resource_group_name           = azurerm_resource_group.avd_eu.name
  location                     = azurerm_resource_group.avd_eu.location
  location_short               = local.pool_configs.dev_eu.location_short
  environment                  = var.environment
  pool_name                    = local.pool_configs.dev_eu.pool_name
  pool_display_name            = local.pool_configs.dev_eu.pool_display_name
  workspace_id                 = module.avd_workspace_eu.workspace_id
  log_analytics_workspace_id   = module.avd_workspace_eu.log_analytics_workspace_id
  host_pool_type              = local.pool_configs.dev_eu.host_pool_type
  maximum_sessions_allowed     = local.pool_configs.dev_eu.max_sessions
  timezone                    = local.pool_configs.dev_eu.timezone
  work_hours_start            = local.pool_configs.dev_eu.work_hours_start
  peak_hours_start            = local.pool_configs.dev_eu.peak_hours_start
  ramp_down_start             = local.pool_configs.dev_eu.ramp_down_start
  off_peak_start              = local.pool_configs.dev_eu.off_peak_start
  tags                        = local.common_tags
}

module "avd_hostpool_dev_us" {
  source = "./modules/avd-hostpool"

  resource_group_name           = azurerm_resource_group.avd_us.name
  location                     = azurerm_resource_group.avd_us.location
  location_short               = local.pool_configs.dev_us.location_short
  environment                  = var.environment
  pool_name                    = local.pool_configs.dev_us.pool_name
  pool_display_name            = local.pool_configs.dev_us.pool_display_name
  workspace_id                 = module.avd_workspace_us.workspace_id
  log_analytics_workspace_id   = module.avd_workspace_us.log_analytics_workspace_id
  host_pool_type              = local.pool_configs.dev_us.host_pool_type
  maximum_sessions_allowed     = local.pool_configs.dev_us.max_sessions
  timezone                    = local.pool_configs.dev_us.timezone
  work_hours_start            = local.pool_configs.dev_us.work_hours_start
  peak_hours_start            = local.pool_configs.dev_us.peak_hours_start
  ramp_down_start             = local.pool_configs.dev_us.ramp_down_start
  off_peak_start              = local.pool_configs.dev_us.off_peak_start
  tags                        = local.common_tags
}

module "avd_hostpool_mgmt_us" {
  source = "./modules/avd-hostpool"

  resource_group_name           = azurerm_resource_group.avd_us.name
  location                     = azurerm_resource_group.avd_us.location
  location_short               = local.pool_configs.mgmt_us.location_short
  environment                  = var.environment
  pool_name                    = local.pool_configs.mgmt_us.pool_name
  pool_display_name            = local.pool_configs.mgmt_us.pool_display_name
  workspace_id                 = module.avd_workspace_us.workspace_id
  log_analytics_workspace_id   = module.avd_workspace_us.log_analytics_workspace_id
  host_pool_type              = local.pool_configs.mgmt_us.host_pool_type
  maximum_sessions_allowed     = local.pool_configs.mgmt_us.max_sessions
  timezone                    = local.pool_configs.mgmt_us.timezone
  work_hours_start            = local.pool_configs.mgmt_us.work_hours_start
  peak_hours_start            = local.pool_configs.mgmt_us.peak_hours_start
  ramp_down_start             = local.pool_configs.mgmt_us.ramp_down_start
  off_peak_start              = local.pool_configs.mgmt_us.off_peak_start
  tags                        = local.common_tags
}

# AVD Session Hosts
module "avd_sessionhosts_dev_eu" {
  source = "./modules/avd-sessionhosts"

  resource_group_name         = azurerm_resource_group.avd_eu.name
  location                   = azurerm_resource_group.avd_eu.location
  pool_name                  = local.pool_configs.dev_eu.pool_name
  pool_type                  = local.pool_configs.dev_eu.pool_type
  subnet_id                  = azurerm_subnet.avd_hosts_eu.id
  session_host_count         = local.pool_configs.dev_eu.session_host_count
  vm_size                    = local.pool_configs.dev_eu.vm_size
  admin_username             = var.avd_admin_username
  admin_password             = var.avd_admin_password
  use_custom_image           = local.pool_configs.dev_eu.use_custom_image
  custom_image_name          = local.pool_configs.dev_eu.custom_image_name
  shared_image_gallery_name  = module.shared_image_gallery.shared_image_gallery_name
  shared_image_gallery_rg    = azurerm_resource_group.avd_eu.name
  host_pool_name             = module.avd_hostpool_dev_eu.host_pool_name
  host_pool_token            = module.avd_hostpool_dev_eu.host_pool_token
  aad_join                   = var.use_aad_join
  domain_join_enabled        = var.domain_join_enabled
  domain_name                = var.domain_name
  domain_join_username       = var.domain_join_username
  domain_join_password       = var.domain_join_password
  #auto_shutdown_enabled      = var.auto_shutdown_enabled
  shutdown_time              = local.pool_configs.dev_eu.shutdown_time
  timezone                   = local.pool_configs.dev_eu.timezone
  tags                       = local.common_tags
}

module "avd_sessionhosts_dev_us" {
  source = "./modules/avd-sessionhosts"

  resource_group_name         = azurerm_resource_group.avd_us.name
  location                   = azurerm_resource_group.avd_us.location
  pool_name                  = local.pool_configs.dev_us.pool_name
  pool_type                  = local.pool_configs.dev_us.pool_type
  subnet_id                  = azurerm_subnet.avd_hosts_us.id
  session_host_count         = local.pool_configs.dev_us.session_host_count
  vm_size                    = local.pool_configs.dev_us.vm_size
  admin_username             = var.avd_admin_username
  admin_password             = var.avd_admin_password
  use_custom_image           = local.pool_configs.dev_us.use_custom_image
  custom_image_name          = local.pool_configs.dev_us.custom_image_name
  shared_image_gallery_name  = module.shared_image_gallery.shared_image_gallery_name
  shared_image_gallery_rg    = azurerm_resource_group.avd_eu.name
  host_pool_name             = module.avd_hostpool_dev_us.host_pool_name
  host_pool_token            = module.avd_hostpool_dev_us.host_pool_token
  aad_join                   = var.use_aad_join
  domain_join_enabled        = var.domain_join_enabled
  domain_name                = var.domain_name
  domain_join_username       = var.domain_join_username
  domain_join_password       = var.domain_join_password
  #auto_shutdown_enabled      = var.auto_shutdown_enabled
  shutdown_time              = local.pool_configs.dev_us.shutdown_time
  timezone                   = local.pool_configs.dev_us.timezone
  tags                       = local.common_tags
}

module "avd_sessionhosts_mgmt_us" {
  source = "./modules/avd-sessionhosts"

  resource_group_name         = azurerm_resource_group.avd_us.name
  location                   = azurerm_resource_group.avd_us.location
  pool_name                  = local.pool_configs.mgmt_us.pool_name
  pool_type                  = local.pool_configs.mgmt_us.pool_type
  subnet_id                  = azurerm_subnet.avd_hosts_us.id
  session_host_count         = local.pool_configs.mgmt_us.session_host_count
  vm_size                    = local.pool_configs.mgmt_us.vm_size
  admin_username             = var.avd_admin_username
  admin_password             = var.avd_admin_password
  use_custom_image           = local.pool_configs.mgmt_us.use_custom_image
  custom_image_name          = local.pool_configs.mgmt_us.custom_image_name
  shared_image_gallery_name  = module.shared_image_gallery.shared_image_gallery_name
  shared_image_gallery_rg    = azurerm_resource_group.avd_eu.name
  host_pool_name             = module.avd_hostpool_mgmt_us.host_pool_name
  host_pool_token            = module.avd_hostpool_mgmt_us.host_pool_token
  aad_join                   = var.use_aad_join
  domain_join_enabled        = var.domain_join_enabled
  domain_name                = var.domain_name
  domain_join_username       = var.domain_join_username
  domain_join_password       = var.domain_join_password
  #auto_shutdown_enabled      = var.auto_shutdown_enabled
  shutdown_time              = local.pool_configs.mgmt_us.shutdown_time
  timezone                   = local.pool_configs.mgmt_us.timezone
  tags                       = local.common_tags
}
