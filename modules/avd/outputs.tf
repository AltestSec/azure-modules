# AVD Module Outputs

output "host_pool_id" {
  description = "ID of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.id
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.name
}

output "workspace_id" {
  description = "ID of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.id
}

output "workspace_name" {
  description = "Name of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.name
}

output "application_group_id" {
  description = "ID of the AVD application group"
  value       = azurerm_virtual_desktop_application_group.main.id
}