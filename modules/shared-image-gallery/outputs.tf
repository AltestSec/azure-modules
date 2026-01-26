# Shared Image Gallery Module Outputs

output "container_registry_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "shared_image_gallery_id" {
  description = "ID of the Shared Image Gallery"
  value       = azurerm_shared_image_gallery.main.id
}

output "shared_image_gallery_name" {
  description = "Name of the Shared Image Gallery"
  value       = azurerm_shared_image_gallery.main.name
}

output "dev_image_id" {
  description = "ID of the development image definition"
  value       = azurerm_shared_image.dev_image.id
}

output "dev_image_name" {
  description = "Name of the development image definition"
  value       = azurerm_shared_image.dev_image.name
}

output "mgmt_image_id" {
  description = "ID of the management image definition"
  value       = azurerm_shared_image.mgmt_image.id
}

output "mgmt_image_name" {
  description = "Name of the management image definition"
  value       = azurerm_shared_image.mgmt_image.name
}