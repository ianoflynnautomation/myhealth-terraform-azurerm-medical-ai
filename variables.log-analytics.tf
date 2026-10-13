variable "log_analytics_name" {
  type        = string
  description = "Name of the Log Analytics workspace that receives diagnostic settings from every service."
  nullable    = false
}

variable "log_analytics_sku" {
  type        = string
  default     = "PerGB2018"
  description = "Log Analytics SKU. PerGB2018 is the current pay-as-you-go SKU."
  nullable    = false
}

variable "log_analytics_retention_in_days" {
  type        = number
  default     = 90
  description = "Workspace retention in days. HIPAA audit typically wants 90+; raise to 365 in prod tfvars if policy requires it."
  nullable    = false

  validation {
    condition     = var.log_analytics_retention_in_days == 7 || (var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730)
    error_message = "log_analytics_retention_in_days must be 7 (Free) or between 30 and 730."
  }
}

variable "log_analytics_internet_ingestion_enabled" {
  type        = string
  default     = "false"
  description = "Whether the workspace accepts ingestion over the public internet. false, true, or SecuredByPerimeter."
  nullable    = false

  validation {
    condition     = contains(["false", "true", "SecuredByPerimeter"], var.log_analytics_internet_ingestion_enabled)
    error_message = "log_analytics_internet_ingestion_enabled must be false, true, or SecuredByPerimeter."
  }
}

variable "log_analytics_internet_query_enabled" {
  type        = string
  default     = "false"
  description = "Whether the workspace accepts queries over the public internet. false, true, or SecuredByPerimeter."
  nullable    = false

  validation {
    condition     = contains(["false", "true", "SecuredByPerimeter"], var.log_analytics_internet_query_enabled)
    error_message = "log_analytics_internet_query_enabled must be false, true, or SecuredByPerimeter."
  }
}
