variable "subscription_id" {
  type        = string
  description = "Azure subscription ID that hosts this stack. Passed to the azurerm and azapi providers; never commit a live value."
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the regional resource group that owns every resource in this stack."
  nullable    = false
}

variable "environment" {
  type        = string
  description = "dev, staging, or prod. Used in tags and default resource name suffixes; never used as a branch in HCL to pick resource shapes."
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure region for every resource. Changing this forces new resources."
  nullable    = false
}

variable "location_short_name" {
  type        = string
  default     = "weu"
  description = "Short region token used in resource names (weu, swn, eus)."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.location_short_name))
    error_message = "location_short_name must be 2-6 lowercase letters."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "AVM module telemetry (modtm). See https://aka.ms/avm/telemetryinfo."
  nullable    = false
}

variable "enable_sql" {
  type        = bool
  default     = true
  description = "Provision Azure SQL (Entra-only auth, TDE, audit). Can be combined with enable_cosmos. Set false in cheap dev — blob + Search is enough for personal RAG."
  nullable    = false
}

variable "enable_cosmos" {
  type        = bool
  default     = true
  description = "Provision Cosmos DB for MongoDB API with autoscale. Can be combined with enable_sql. Set false in cheap dev."
  nullable    = false
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Provision a NAT Gateway and public IP on the app subnet. Disable in cheap dev (~$37/month saved). When false, the app subnet uses Azure default outbound access."
  nullable    = false
}

variable "enable_private_endpoints" {
  type        = bool
  default     = true
  description = "Create private endpoints and privatelink DNS zones, and keep PaaS public access off. Disable in cheap dev (~$58/month saved) so a laptop can reach the data plane. Staging/prod must leave this true (ADR-0003)."
  nullable    = false
}

variable "enable_foundry" {
  type        = bool
  default     = true
  description = "Provision Azure AI Foundry (account, project, model deployments, BYOR connections). Disable in mocked unit tests; the nested AVM uses ephemeral resources the mock provider cannot plan."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags merged onto the default workload/environment/managed_by/data_classification set."
  nullable    = false
}
