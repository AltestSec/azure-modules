# Infrastructure Module Variables

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

variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing"
  type        = bool
  default     = false
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}