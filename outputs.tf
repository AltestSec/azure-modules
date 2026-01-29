# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = azurerm_public_ip.main[*].ip_address
}

output "vm_names" {
  description = "Names of the created VMs"
  value       = azurerm_linux_virtual_machine.main[*].name
}

output "service_bus_namespace" {
  description = "Service Bus namespace details"
  value = {
    name              = module.sbus.namespace_name
    connection_string = module.sbus.primary_connection_string
  }
  sensitive = true
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to VMs"
  value = [
    for i, vm in azurerm_linux_virtual_machine.main :
    "ssh adminuser@${azurerm_public_ip.main[i].ip_address}"
  ]
}