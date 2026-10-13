output "resource_group_name" {
  description = "Name of the regional resource group."
  value       = module.rg.name
}

output "resource_group_id" {
  description = "Resource ID of the regional resource group."
  value       = module.rg.resource_id
}

output "virtual_network_id" {
  description = "Resource ID of the pipeline virtual network."
  value       = module.virtual_network.resource_id
}

output "app_subnet_id" {
  description = "Resource ID of the app/compute subnet (NAT egress, no implicit SNAT)."
  value       = module.virtual_network.subnets["app"].resource_id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the private-endpoint subnet."
  value       = module.virtual_network.subnets["private_endpoints"].resource_id
}

output "nat_gateway_resource_id" {
  description = "Resource ID of the NAT Gateway attached to the app subnet. Null when enable_nat_gateway is false."
  value       = try(module.nat_gateway[0].resource_id, null)
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace that receives diagnostic settings."
  value       = module.log_analytics.resource_id
}

output "kv_uri" {
  description = "Key Vault URI. Data-plane operations require network access via the private endpoint."
  value       = module.key_vault.uri
}

output "kv_resource_id" {
  description = "Resource ID of the Key Vault."
  value       = module.key_vault.resource_id
}

output "cmk_key_id" {
  description = "Key Vault key used as the customer-managed key for data-at-rest encryption."
  value       = try(module.key_vault.keys[var.kv_cmk_key_name].id, null)
}

output "storage_account_name" {
  description = "Name of the pipeline storage account (inbound PDFs, extracted JSON, indexer staging)."
  value       = module.storage.name
}

output "storage_account_id" {
  description = "Resource ID of the pipeline storage account."
  value       = module.storage.resource_id
}

output "storage_blob_endpoint" {
  description = "Blob endpoint of the pipeline storage account. Resolves privately via privatelink.blob.core.windows.net."
  value       = "https://${module.storage.name}.blob.core.windows.net/"
}

output "document_intelligence_id" {
  description = "Resource ID of the Document Intelligence account."
  value       = module.document_intelligence.resource_id
}

output "document_intelligence_endpoint" {
  description = "HTTPS endpoint of Document Intelligence. Token auth via the document_intelligence user-assigned identity; API keys are disabled."
  value       = "https://${var.document_intelligence_custom_subdomain_name}.cognitiveservices.azure.com/"
}

output "search_service_id" {
  description = "Resource ID of the AI Search service."
  value       = module.ai_search.resource_id
}

output "search_endpoint" {
  description = "HTTPS endpoint of AI Search. Semantic ranking is enabled; API keys are disabled."
  value       = "https://${var.search_name}.search.windows.net"
}

output "sql_server_id" {
  description = "Resource ID of the Azure SQL logical server. Null when enable_sql is false."
  value       = try(module.sql[0].resource_id, null)
}

output "sql_server_fqdn" {
  description = "FQDN of the Azure SQL logical server. Null when enable_sql is false. Resolves privately via privatelink.database.windows.net."
  value       = try(module.sql[0].resource_name, null) == null ? null : "${var.sql_server_name}.database.windows.net"
}

output "cosmos_account_id" {
  description = "Resource ID of the Cosmos DB account. Null when enable_cosmos is false."
  value       = try(module.cosmos[0].resource_id, null)
}

output "foundry_id" {
  description = "Resource ID of the Azure AI Foundry account. Null when enable_foundry is false."
  value       = try(module.ai_foundry[0].ai_foundry_id, null)
}

output "foundry_project_id" {
  description = "Resource ID of the medical extraction Foundry project. Null when enable_foundry is false."
  value       = try(module.ai_foundry[0].ai_foundry_project_id, null)
}

output "identity_client_ids" {
  description = "Map of logical identity key => application (client) ID. Annotate compute workloads with these."
  value       = module.workload_identities.client_ids
}

output "identity_principal_ids" {
  description = "Map of logical identity key => principal (object) ID. Used for additional RBAC outside this stack."
  value       = module.workload_identities.principal_ids
}

output "identity_ids" {
  description = "Map of logical identity key => user-assigned identity resource ID."
  value       = module.workload_identities.ids
}
