variable "resource_group_name" {
  type        = string
  description = "Resource group all identities are created in."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region for the identities."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every identity."
  default     = {}
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable AVM module telemetry (modtm provider) on every identity."
  default     = false
  nullable    = false
}

variable "identities" {
  type = map(object({
    name = string

    federated_identity_credentials = optional(map(object({
      audience = list(string)
      issuer   = string
      name     = string
      subject  = string
    })), {})

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      scope                                  = string
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, null)
    })), {})
  }))
  description = <<-EOT
  Map of workload identities to create. Key is a stable logical name (e.g. "pipeline", "foundry") used by callers to look up outputs.

  - `name` - Final Azure name of the user-assigned identity.
  - `federated_identity_credentials` - FIC map forwarded to the user-assigned-identity primitive.
  - `role_assignments` - Role assignment map forwarded to the user-assigned-identity primitive.
  EOT
  nullable    = false

  validation {
    condition     = alltrue([for k, v in var.identities : length(trimspace(v.name)) > 0])
    error_message = "Every identities entry must set a non-empty name."
  }
}
