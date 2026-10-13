variable "sql_server_name" {
  type        = string
  default     = "sql-medai-dev-weu-01"
  description = "Azure SQL logical server name. 2-63 lowercase letters, numbers, and hyphens."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.sql_server_name))
    error_message = "sql_server_name must be 2-63 characters, start and end alphanumeric, lowercase, and may contain hyphens."
  }
}

variable "sql_server_version" {
  type        = string
  default     = "12.0"
  description = "SQL Server version. 12.0 is current Azure SQL."
  nullable    = false
}

variable "sql_database_name" {
  type        = string
  default     = "medical"
  description = "Name of the Azure SQL database that stores extracted medical records."
  nullable    = false
}

variable "sql_database_sku_name" {
  type        = string
  default     = "GP_S_Gen5_2"
  description = "Database SKU. GP_S_Gen5_2 is serverless general purpose (dev-friendly). Use GP_Gen5_2 or higher in prod tfvars."
  nullable    = false
}

variable "sql_database_max_size_gb" {
  type        = number
  default     = 32
  description = "Maximum database size in GB."
  nullable    = false
}

variable "sql_database_collation" {
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
  description = "Database collation. Changing this forces a new database."
  nullable    = false
}

variable "sql_database_min_capacity" {
  type        = number
  default     = 0.5
  description = "Serverless minimum vCores. Ignored by Azure when the SKU is not GP_S_*."
  nullable    = false
}

variable "sql_database_auto_pause_delay_in_minutes" {
  type        = number
  default     = 60
  description = "Serverless auto-pause delay in minutes. -1 disables auto-pause. Ignored when the SKU is not GP_S_*."
  nullable    = false
}

variable "sql_database_zone_redundant" {
  type        = bool
  default     = false
  description = "Zone-redundant database. Enable in prod regions that support it."
  nullable    = false
}

variable "sql_database_ledger_enabled" {
  type        = bool
  default     = false
  description = "Enable SQL ledger for tamper-evident medical record tables. Forces a new database when changed."
  nullable    = false
}

variable "sql_database_storage_account_type" {
  type        = string
  default     = "Zone"
  description = "Backup storage redundancy: Geo, GeoZone, Local, or Zone."
  nullable    = false

  validation {
    condition     = contains(["Geo", "GeoZone", "Local", "Zone"], var.sql_database_storage_account_type)
    error_message = "sql_database_storage_account_type must be Geo, GeoZone, Local, or Zone."
  }
}

variable "sql_database_short_term_retention_days" {
  type        = number
  default     = 7
  description = "Point-in-time restore retention in days (1-35)."
  nullable    = false

  validation {
    condition     = var.sql_database_short_term_retention_days >= 1 && var.sql_database_short_term_retention_days <= 35
    error_message = "sql_database_short_term_retention_days must be between 1 and 35."
  }
}

variable "sql_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether the SQL logical server is reachable from the public internet. Default false; private endpoint only."
  nullable    = false
}

variable "sql_connection_policy" {
  type        = string
  default     = "Default"
  description = "SQL connection policy: Default, Proxy, or Redirect."
  nullable    = false

  validation {
    condition     = contains(["Default", "Proxy", "Redirect"], var.sql_connection_policy)
    error_message = "sql_connection_policy must be Default, Proxy, or Redirect."
  }
}

variable "sql_express_vulnerability_assessment_enabled" {
  type        = bool
  default     = true
  description = "Enable Express Vulnerability Assessment on the SQL server."
  nullable    = false
}

variable "sql_azuread_admin_login_username" {
  type        = string
  default     = null
  description = "Display name of the Entra administrator for Azure SQL. When null, 'terraform' is used with the current client object ID."
}

variable "sql_azuread_admin_object_id" {
  type        = string
  default     = null
  description = "Object ID of the Entra administrator for Azure SQL. When null, the current client object ID is used. SQL authentication is disabled (azuread_authentication_only = true)."
}

variable "sql_audit_retention_in_days" {
  type        = number
  default     = 90
  description = "SQL auditing and security-alert retention in days. Events also stream to Log Analytics."
  nullable    = false
}

variable "sql_security_alert_email_account_admins" {
  type        = bool
  default     = true
  description = "Email the Entra SQL admin on Defender for SQL alerts."
  nullable    = false
}

variable "sql_security_alert_email_addresses" {
  type        = list(string)
  default     = []
  description = "Additional email addresses for Defender for SQL alerts. Do not put PHI in the addresses; they are just destinations."
  nullable    = false
}
