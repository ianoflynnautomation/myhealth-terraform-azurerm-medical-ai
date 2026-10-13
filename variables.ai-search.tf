variable "search_name" {
  type        = string
  description = "Name of the Azure AI Search service used to index extracted JSON for RAG."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$", var.search_name))
    error_message = "search_name must be 3-60 lowercase alphanumeric characters and hyphens, start and end alphanumeric."
  }
}

variable "search_location" {
  type        = string
  default     = null
  description = "Azure region for the AI Search service. Null (the default) keeps it in var.location with everything else. Override only to work around InsufficientResourcesAvailable in the primary region: it places the search index outside the primary region, which is a data-residency decision for PHI, and makes the Storage/SQL/Cosmos indexers and any private endpoint cross-region."
}

variable "search_sku" {
  type        = string
  default     = "standard"
  description = "AI Search SKU. Semantic ranking requires basic or higher; standard is the production default."
  nullable    = false

  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.search_sku)
    error_message = "search_sku must be a valid Azure AI Search SKU."
  }
}

variable "search_semantic_search_sku" {
  type        = string
  default     = "standard"
  description = "Semantic ranker SKU. free or standard. Set null to disable semantic search."
  nullable    = true

  validation {
    condition     = var.search_semantic_search_sku == null || contains(["free", "standard"], var.search_semantic_search_sku)
    error_message = "search_semantic_search_sku must be free, standard, or null."
  }
}

variable "search_replica_count" {
  type        = number
  default     = 1
  description = "Search replicas. Two or more are required for query HA (not available on free)."
  nullable    = false

  validation {
    condition     = var.search_replica_count >= 1 && var.search_replica_count <= 12
    error_message = "search_replica_count must be between 1 and 12."
  }
}

variable "search_partition_count" {
  type        = number
  default     = 1
  description = "Search partitions for document-count scaling."
  nullable    = false

  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.search_partition_count)
    error_message = "search_partition_count must be one of: 1, 2, 3, 4, 6, 12."
  }
}

variable "search_hosting_mode" {
  type        = string
  default     = "default"
  description = "Search hosting mode. default or highDensity."
  nullable    = false

  validation {
    condition     = contains(["default", "highDensity"], var.search_hosting_mode)
    error_message = "search_hosting_mode must be default or highDensity."
  }
}

variable "search_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether AI Search is reachable from the public internet. Default false; private endpoint only."
  nullable    = false
}
