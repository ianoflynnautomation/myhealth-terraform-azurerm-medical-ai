resource "azurerm_role_assignment" "search_reads_blobs" {
  scope                = module.storage.resource_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = local.search_principal_id
  description          = "AI Search reads extracted medical JSON from blob storage to build the RAG index."
}

resource "azurerm_role_assignment" "search_cmk_crypto_user" {
  count = var.kv_cmk_enabled ? 1 : 0

  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = local.search_principal_id
  description          = "AI Search unwraps the customer-managed key. Only needed while kv_cmk_enabled is true."
}

resource "azurerm_role_assignment" "search_reads_sql" {
  count = var.enable_sql ? 1 : 0

  scope                = module.sql[0].resource_id
  role_definition_name = "Reader"
  principal_id         = local.search_principal_id
  description          = "AI Search identity reads SQL metadata for indexers over extracted medical records."
}

resource "azurerm_role_assignment" "search_sql_contributor" {
  count = var.enable_sql ? 1 : 0

  scope                = module.sql[0].resource_id
  role_definition_name = "SQL DB Contributor"
  principal_id         = local.search_principal_id
  description          = "AI Search indexer reads the extracted-records tables."
}

resource "azurerm_role_assignment" "search_reads_cosmos" {
  count = var.enable_cosmos ? 1 : 0

  scope                = module.cosmos[0].resource_id
  role_definition_name = "Reader"
  principal_id         = local.search_principal_id
  description          = "AI Search identity reads Cosmos metadata for Mongo indexers over extracted medical records."
}

resource "azurerm_role_assignment" "search_cosmos_contributor" {
  count = var.enable_cosmos ? 1 : 0

  scope                = module.cosmos[0].resource_id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = local.search_principal_id
  description          = "AI Search Mongo indexer reads the extracted-records collection."
}

resource "azurerm_role_assignment" "pipeline_cognitive_contributor" {
  scope                = module.document_intelligence.resource_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = module.workload_identities.principal_ids["pipeline"]
  description          = "Pipeline identity manages Document Intelligence model/read operations without API keys."
}

resource "azurerm_role_assignment" "foundry_on_search" {
  count = var.enable_foundry ? 1 : 0

  scope                = module.ai_search.resource_id
  role_definition_name = "Search Service Contributor"
  principal_id         = module.workload_identities.principal_ids["foundry"]
  description          = "Foundry project identity manages AI Search indexes used by RAG connections."
}
