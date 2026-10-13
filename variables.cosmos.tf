variable "cosmos_account_name" {
  type        = string
  default     = "cosmos-medai-dev-weu-01"
  description = "Cosmos DB account name. 3-44 lowercase letters, numbers, and hyphens."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,42}[a-z0-9]$", var.cosmos_account_name))
    error_message = "cosmos_account_name must be 3-44 lowercase alphanumeric characters and hyphens, start and end alphanumeric."
  }
}

variable "cosmos_mongo_server_version" {
  type        = string
  default     = "7.0"
  description = "MongoDB server version on the Cosmos account."
  nullable    = false

  validation {
    condition     = contains(["3.2", "3.6", "4.0", "4.2", "5.0", "6.0", "7.0"], var.cosmos_mongo_server_version)
    error_message = "cosmos_mongo_server_version must be a supported Cosmos MongoDB version."
  }
}

variable "cosmos_database_name" {
  type        = string
  default     = "medical"
  description = "MongoDB database name for extracted records."
  nullable    = false
}

variable "cosmos_collection_name" {
  type        = string
  default     = "extracted-records"
  description = "MongoDB collection name for extracted JSON medical records."
  nullable    = false
}

variable "cosmos_shard_key" {
  type        = string
  default     = "patientId"
  description = "Shard key path for the Mongo collection. Changing this forces a new collection."
  nullable    = false
}

variable "cosmos_autoscale_max_throughput" {
  type        = number
  default     = 4000
  description = "Autoscale max RU/s for the Mongo database. Must be between 1000 and 1000000 in increments of 1000."
  nullable    = false

  validation {
    condition     = var.cosmos_autoscale_max_throughput >= 1000 && var.cosmos_autoscale_max_throughput <= 1000000 && var.cosmos_autoscale_max_throughput % 1000 == 0
    error_message = "cosmos_autoscale_max_throughput must be 1000-1000000 in increments of 1000."
  }
}

variable "cosmos_consistency_level" {
  type        = string
  default     = "Session"
  description = "Cosmos consistency level."
  nullable    = false

  validation {
    condition     = contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], var.cosmos_consistency_level)
    error_message = "cosmos_consistency_level must be a valid Cosmos consistency level."
  }
}

variable "cosmos_backup_tier" {
  type        = string
  default     = "Continuous7Days"
  description = "Continuous backup tier. Continuous7Days or Continuous30Days."
  nullable    = false

  validation {
    condition     = contains(["Continuous7Days", "Continuous30Days"], var.cosmos_backup_tier)
    error_message = "cosmos_backup_tier must be Continuous7Days or Continuous30Days."
  }
}

variable "cosmos_zone_redundant" {
  type        = bool
  default     = false
  description = "Zone redundancy for the primary Cosmos region. Enable in prod regions that support it."
  nullable    = false
}

variable "cosmos_automatic_failover_enabled" {
  type        = bool
  default     = true
  description = "Enable automatic failover for the Cosmos account."
  nullable    = false
}

variable "cosmos_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether Cosmos DB is reachable from the public internet. Default false; private endpoint only."
  nullable    = false
}
