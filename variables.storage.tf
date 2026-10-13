variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name for inbound PDFs, extracted JSON, and indexer staging. 3-24 lowercase alphanumeric characters."
  nullable    = false

  validation {
    condition = (
      length(var.storage_account_name) >= 3
      && length(var.storage_account_name) <= 24
      && can(regex("^[a-z0-9]+$", var.storage_account_name))
    )
    error_message = "storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "storage_account_tier" {
  type        = string
  default     = "Standard"
  description = "Performance tier for the pipeline storage account (Standard or Premium)."
  nullable    = false

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  type        = string
  default     = "ZRS"
  description = "Replication type (LRS, ZRS, GRS, GZRS). ZRS is the HIPAA-friendly default in regions that support it."
  nullable    = false

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.storage_replication_type)
    error_message = "storage_replication_type must be one of: LRS, ZRS, GRS, GZRS, RAGRS, RAGZRS."
  }
}

variable "storage_min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version accepted by the storage account."
  nullable    = false

  validation {
    condition     = contains(["TLS1_2", "TLS1_3"], var.storage_min_tls_version)
    error_message = "storage_min_tls_version must be TLS1_2 or TLS1_3."
  }
}

variable "storage_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether the storage account is reachable from the public internet. Default false; private endpoint only."
  nullable    = false
}

variable "storage_ip_rules" {
  type        = set(string)
  default     = []
  description = "Optional public IPv4 addresses or CIDRs allowed through the storage firewall. RFC 1918 ranges are rejected by Azure."
  nullable    = false
}

variable "storage_containers" {
  type = map(object({
    name          = string
    public_access = optional(string, "None")
    metadata      = optional(map(string), {})
  }))
  default = {
    inbound_pdfs = {
      name          = "inbound-pdfs"
      public_access = "None"
    }
    extracted_json = {
      name          = "extracted-json"
      public_access = "None"
    }
    search_staging = {
      name          = "search-staging"
      public_access = "None"
    }
  }
  description = "Blob containers for the extraction pipeline. public_access must stay None — PHI is never anonymously readable."
  nullable    = false

  validation {
    condition     = alltrue([for _, c in var.storage_containers : contains(["None", "Blob", "Container"], c.public_access)])
    error_message = "storage_containers.*.public_access must be None, Blob, or Container. Keep None for PHI."
  }
}
