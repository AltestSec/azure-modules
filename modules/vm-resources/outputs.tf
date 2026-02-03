# VM Resources Module Outputs

output "vm_ids" {
  description = "IDs of the created VMs"
  value       = azurerm_linux_virtual_machine.vm[*].id
}

output "vm_names" {
  description = "Names of the created VMs"
  value       = azurerm_linux_virtual_machine.vm[*].name
}

output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = azurerm_public_ip.vm_pip[*].ip_address
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = azurerm_network_interface.vm_nic[*].private_ip_address
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.vm_nsg.id
}

output "network_interface_ids" {
  description = "IDs of the network interfaces"
  value       = azurerm_network_interface.vm_nic[*].id
}