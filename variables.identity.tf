variable "pipeline_identity_name_prefix" {
  type        = string
  default     = "id-medai-pipeline-"
  description = "Prefix for the pipeline orchestrator user-assigned identity. Final name is <prefix><environment>-<location_short_name>."
  nullable    = false
}

variable "document_intelligence_identity_name_prefix" {
  type        = string
  default     = "id-medai-di-"
  description = "Prefix for the Document Intelligence user-assigned identity."
  nullable    = false
}

variable "foundry_identity_name_prefix" {
  type        = string
  default     = "id-medai-foundry-"
  description = "Prefix for the AI Foundry user-assigned identity."
  nullable    = false
}

variable "search_identity_name_prefix" {
  type        = string
  default     = "id-medai-search-"
  description = "Prefix for the AI Search user-assigned identity."
  nullable    = false
}

variable "sql_identity_name_prefix" {
  type        = string
  default     = "id-medai-sql-"
  description = "Prefix for the Azure SQL user-assigned identity (used for TDE CMK and Entra auth)."
  nullable    = false
}

variable "cosmos_identity_name_prefix" {
  type        = string
  default     = "id-medai-cosmos-"
  description = "Prefix for the Cosmos DB user-assigned identity (used for CMK)."
  nullable    = false
}

variable "cmk_identity_name_prefix" {
  type        = string
  default     = "id-medai-cmk-"
  description = "Prefix for the customer-managed-key user-assigned identity. Granted Key Vault Crypto Service Encryption User on the vault."
  nullable    = false
}
