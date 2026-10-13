variable "kv_name" {
  type        = string
  description = "Name of the Key Vault. 3-24 characters, letters, numbers, and dashes; must start with a letter."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.kv_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain letters, numbers and dashes."
  }
  validation {
    error_message = "The name must not contain two consecutive dashes."
    condition     = !can(regex("--", var.kv_name))
  }
  validation {
    error_message = "The name must start with a letter."
    condition     = can(regex("^[a-zA-Z]", var.kv_name))
  }
  validation {
    error_message = "The name must end with a letter or number."
    condition     = can(regex("[a-zA-Z0-9]$", var.kv_name))
  }
}

variable "kv_sku_name" {
  type        = string
  default     = "premium"
  description = "Key Vault SKU. premium is required for HSM-backed keys; standard is software-protected RSA."
  nullable    = false

  validation {
    condition     = contains(["standard", "premium"], var.kv_sku_name)
    error_message = "kv_sku_name must be standard or premium."
  }
}

variable "kv_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether the Key Vault data plane is reachable from the public internet. Default false (private endpoint only). Terraform apply of secrets then requires a runner inside the VNet; flip to true only for a laptop bootstrap and revert. See ADR-0003."
  nullable    = false
}

variable "kv_purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Enable purge protection. Once enabled this cannot be disabled."
  nullable    = false
}

variable "kv_purge_soft_delete_on_destroy" {
  type        = bool
  default     = false
  description = "Provider feature: purge the vault on destroy. Keep false in every environment that has purge protection enabled."
  nullable    = false
}

variable "kv_soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "Soft-delete retention in days (7-90)."

  validation {
    condition     = var.kv_soft_delete_retention_days >= 7 && var.kv_soft_delete_retention_days <= 90
    error_message = "kv_soft_delete_retention_days must be between 7 and 90."
  }
}

variable "kv_enabled_for_disk_encryption" {
  type        = bool
  default     = false
  description = "Allow Azure Disk Encryption to unwrap keys from this vault."
  nullable    = false
}

variable "kv_cmk_enabled" {
  type        = bool
  default     = true
  description = "Attach the Key Vault CMK to Storage, Document Intelligence, Search, SQL TDE, Cosmos, and Foundry. The RSA key is always created; this flag only controls whether services use it."
  nullable    = false
}

variable "kv_cmk_key_name" {
  type        = string
  default     = "cmk-medical-pipeline"
  description = "Name of the RSA-4096 key used as the customer-managed key for data-at-rest encryption."
  nullable    = false
}

variable "kv_network_acls" {
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default     = {}
  description = "Network ACL for the Key Vault. Default Deny with AzureServices bypass. Set ip_rules to allow a bootstrap runner if kv_public_network_access_enabled is temporarily true."

  validation {
    condition     = contains(["AzureServices", "None"], var.kv_network_acls.bypass)
    error_message = "kv_network_acls.bypass must be AzureServices or None."
  }
  validation {
    condition     = contains(["Allow", "Deny"], var.kv_network_acls.default_action)
    error_message = "kv_network_acls.default_action must be Allow or Deny."
  }
}

variable "kv_private_endpoints" {
  type = map(object({
    name                          = optional(string, null)
    subnet_resource_id            = string
    private_dns_zone_resource_ids = optional(set(string), [])
    private_dns_zone_group_name   = optional(string, "default")
    location                      = optional(string, null)
    resource_group_name           = optional(string, null)
    tags                          = optional(map(string), null)
  }))
  default     = {}
  description = "Extra private endpoints merged onto the vault endpoint this module always creates. The map key is arbitrary so it can be unknown at plan time."
  nullable    = false
}

variable "kv_wait_for_rbac_before_key_operations" {
  type = object({
    create  = optional(string, "60s")
    destroy = optional(string, "0s")
  })
  default     = {}
  description = "Wait after role assignment before creating keys. Raised to 60s because CMK consumers apply immediately after."
}

variable "kv_wait_for_rbac_before_secret_operations" {
  type = object({
    create  = optional(string, "30s")
    destroy = optional(string, "0s")
  })
  default     = {}
  description = "Wait after role assignment before creating secrets."
  nullable    = false
}
