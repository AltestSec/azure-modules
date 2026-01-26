# Service Bus Module Outputs
output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.id
}

output "primary_connection_string" {
  description = "Primary connection string for the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive   = true
}

output "topic_name" {
  description = "Name of the Service Bus topic"
  value       = azurerm_servicebus_topic.main.name
}

output "topic_id" {
  description = "ID of the Service Bus topic"
  value       = azurerm_servicebus_topic.main.id
}

output "subscription_names" {
  description = "Names of the Service Bus subscriptions"
  value       = [for sub in azurerm_servicebus_subscription.main : sub.name]
}