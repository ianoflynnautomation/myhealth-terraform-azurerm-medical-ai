output "ids" {
  description = "Map of identity key => resource ID of the user-assigned identity."
  value       = { for k, m in module.identity : k => m.resource_id }
}

output "client_ids" {
  description = "Map of identity key => client ID. Used for compute identity configuration."
  value       = { for k, m in module.identity : k => m.client_id }
}

output "principal_ids" {
  description = "Map of identity key => principal (object) ID. Used for Azure RBAC role assignments."
  value       = { for k, m in module.identity : k => m.principal_id }
}

output "names" {
  description = "Map of identity key => Azure name of the identity."
  value       = { for k, m in module.identity : k => m.resource_name }
}
