# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "service_bus_topic_name" {
  description = "Name of the Service Bus topic"
  type        = string
  default     = "main-topic"
}

variable "service_bus_subscriptions" {
  description = "List of Service Bus subscription names"
  type        = list(string)
  default     = ["post-subscription", "video-subscription"]
}