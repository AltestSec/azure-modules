# AVD Session Hosts Module Outputs

output "session_host_names" {
  description = "Names of the session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].name
}

output "session_host_ids" {
  description = "IDs of the session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].id
}

output "session_host_private_ips" {
  description = "Private IP addresses of the session hosts"
  value       = azurerm_network_interface.session_host[*].private_ip_address
}

output "session_host_computer_names" {
  description = "Computer names of the session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].computer_name
}