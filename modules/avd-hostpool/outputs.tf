# AVD Host Pool Module Outputs

output "host_pool_id" {
  description = "ID of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.id
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.name
}

output "host_pool_token" {
  description = "Registration token for the host pool"
  value       = azurerm_virtual_desktop_host_pool.main.registration_info[0].token
  sensitive   = true
}

output "application_group_id" {
  description = "ID of the application group"
  value       = azurerm_virtual_desktop_application_group.main.id
}

output "application_group_name" {
  description = "Name of the application group"
  value       = azurerm_virtual_desktop_application_group.main.name
}

output "scaling_plan_id" {
  description = "ID of the scaling plan"
  value       = var.host_pool_type == "Pooled" ? azurerm_virtual_desktop_scaling_plan.main[0].id : null
}