# Service Bus Namespace
resource "azurerm_servicebus_namespace" "main" {
  name                = "sbus-${var.environment}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  local_auth_enabled           = true

  tags = {
    Environment = var.environment
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Service Bus Topic
resource "azurerm_servicebus_topic" "main" {
  name         = var.service_bus_topic_name
  namespace_id = azurerm_servicebus_namespace.main.id

  batched_operations_enabled     = true
  express_enabled               = false
  partitioning_enabled          = false
  requires_duplicate_detection = false
  support_ordering            = false
  
  max_size_in_megabytes = 1024
  default_message_ttl   = "P14D"

  depends_on = [azurerm_servicebus_namespace.main]
}

# Service Bus Subscriptions
resource "azurerm_servicebus_subscription" "main" {
  for_each = toset(var.service_bus_subscriptions)
  
  name     = each.value
  topic_id = azurerm_servicebus_topic.main.id

  batched_operations_enabled                = true
  dead_lettering_on_message_expiration     = false
  dead_lettering_on_filter_evaluation_error = false
  requires_session                         = false
  
  max_delivery_count  = 5
  lock_duration      = "PT1M"
  default_message_ttl = "P14D"

  depends_on = [azurerm_servicebus_topic.main]
}