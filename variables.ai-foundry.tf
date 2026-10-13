variable "foundry_base_name" {
  type        = string
  default     = "medai"
  description = "3-7 character affix used by the Foundry pattern module when a custom resource name is not supplied."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,5}[a-z0-9]$", var.foundry_base_name))
    error_message = "foundry_base_name must be 3-7 characters, start and end alphanumeric, lowercase, and may contain hyphens."
  }
}

variable "foundry_name" {
  type        = string
  description = "Name of the Azure AI Foundry (AI Services) account."
  nullable    = false
}

variable "foundry_sku" {
  type        = string
  default     = "S0"
  description = "AI Foundry account SKU."
  nullable    = false
}

variable "foundry_project_name" {
  type        = string
  default     = "medical-extraction"
  description = "Name of the AI Foundry project that owns connections to Search, Storage, Key Vault, and Cosmos."
  nullable    = false
}

variable "foundry_project_display_name" {
  type        = string
  default     = "Medical extraction"
  description = "Display name of the AI Foundry project."
  nullable    = false
}

variable "foundry_project_description" {
  type        = string
  default     = "RAG project over JSON medical records extracted by Document Intelligence."
  description = "Description of the AI Foundry project."
  nullable    = false
}

variable "foundry_create_ai_agent_service" {
  type        = bool
  default     = false
  description = "Create the Foundry agent capability host. Keep false until Standard Agent Setup (BYO Cosmos/Storage/Search) is required. Requires enable_cosmos."
  nullable    = false

  # The capability host keeps thread storage in Cosmos, and the module only
  # builds it alongside the project connections (ADR-0005).
  validation {
    condition     = !var.foundry_create_ai_agent_service || var.enable_cosmos
    error_message = "foundry_create_ai_agent_service requires enable_cosmos = true: the agent capability host keeps thread storage in Cosmos, and the Foundry pattern module only wires project connections when a Cosmos account exists."
  }
}

variable "foundry_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether the Foundry account is reachable from the public internet. Default false; private endpoint only."
  nullable    = false
}

variable "foundry_model_deployments" {
  type = map(object({
    name                   = string
    rai_policy_name        = optional(string, "Microsoft.DefaultV2")
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      capacity = optional(number)
      family   = optional(string)
      size     = optional(string)
      tier     = optional(string)
      type     = string
    })
  }))
  default = {
    gpt4o = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-11-20"
      }
      scale = {
        type     = "Standard"
        capacity = 10
      }
    }
    embeddings = {
      name = "text-embedding-3-large"
      model = {
        format  = "OpenAI"
        name    = "text-embedding-3-large"
        version = "1"
      }
      scale = {
        type     = "Standard"
        capacity = 10
      }
    }
  }
  description = "Model deployments on the Foundry account. gpt-4o for extraction/RAG generation and text-embedding-3-large for indexing. Override per environment for quota."
  nullable    = false
}
