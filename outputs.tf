# Outputs for debugging and verification

output "resource_prefix" {
  description = "Resource prefix used"
  value       = var.resource_prefix
}

output "resource_group_name" {
  description = "Resource group name"
  value       = local.resource_group_name
}

output "common_tags" {
  description = "Common tags applied to resources"
  value       = local.common_tags
}

output "backend_config" {
  description = "Backend configuration reference"
  value       = local.backend_config
}

output "due_date" {
  description = "Calculated due date"
  value       = local.due_date
}