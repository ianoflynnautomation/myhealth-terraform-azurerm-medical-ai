variable "document_intelligence_name" {
  type        = string
  description = "Name of the Azure AI Document Intelligence (FormRecognizer) account."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,62}[a-zA-Z0-9]$", var.document_intelligence_name))
    error_message = "document_intelligence_name must be 3-64 characters, start and end alphanumeric, and may contain hyphens."
  }
}

variable "document_intelligence_custom_subdomain_name" {
  type        = string
  description = "Custom subdomain for token-based auth and private endpoints. Required; changing it forces a new account."
  nullable    = false
}

variable "document_intelligence_sku" {
  type        = string
  default     = "S0"
  description = "Document Intelligence SKU. S0 is the paid production SKU; F0 is free-tier and is not HIPAA-eligible."
  nullable    = false

  validation {
    condition     = contains(["F0", "S0"], var.document_intelligence_sku)
    error_message = "document_intelligence_sku must be F0 or S0."
  }
}

variable "document_intelligence_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether Document Intelligence is reachable from the public internet. Default false; private endpoint only."
  nullable    = false
}

variable "document_intelligence_outbound_network_access_restricted" {
  type        = bool
  default     = true
  description = "Restrict outbound network access from the Document Intelligence account."
  nullable    = false
}

variable "document_intelligence_byo_storage_enabled" {
  type        = bool
  default     = false
  description = "Attach the pipeline storage account to the Document Intelligence account as bring-your-own storage. Requires the BYOS feature to be enabled on the subscription and is not supported by every kind/SKU — FormRecognizer on F0 rejects it with 400 BringOwnFeatureNotEnabled. Note that Document Intelligence v3+ takes a per-request blob URL for custom-model training data, so this account-level attachment is not what keeps extracted PHI in your own storage account."
  nullable    = false
}
