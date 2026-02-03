# Service Bus Resources
# This file contains Service Bus module and related resources

# Data source for existing resource group
data "azurerm_resource_group" "sbus_rg" {
  name = var.resource_group_name
}

# Service Bus Module
module "sbus" {
  source = "./modules/sbus"

  resource_group_name = data.azurerm_resource_group.sbus_rg.name
  location            = data.azurerm_resource_group.sbus_rg.location
  environment         = var.environment
}