# Infrastructure Module Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = local.resource_group.location
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = local.resource_group.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vm_subnet_id" {
  description = "ID of the VM subnet"
  value       = azurerm_subnet.vm_subnet.id
}

output "vm_subnet_name" {
  description = "Name of the VM subnet"
  value       = azurerm_subnet.vm_subnet.name
}

output "avd_subnet_id" {
  description = "ID of the AVD subnet"
  value       = azurerm_subnet.avd_subnet.id
}

output "avd_subnet_name" {
  description = "Name of the AVD subnet"
  value       = azurerm_subnet.avd_subnet.name
}

output "services_subnet_id" {
  description = "ID of the services subnet"
  value       = azurerm_subnet.services_subnet.id
}

output "services_subnet_name" {
  description = "Name of the services subnet"
  value       = azurerm_subnet.services_subnet.name
}