# AVD Workspace Module Outputs

output "workspace_id" {
  description = "ID of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.id
}

output "workspace_name" {
  description = "Name of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.avd.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.avd.name
}