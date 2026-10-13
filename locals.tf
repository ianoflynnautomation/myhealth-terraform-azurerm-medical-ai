locals {
  tags = merge({
    workload            = "medical-ai-pipeline"
    environment         = var.environment
    managed_by          = "terraform"
    data_classification = "phi"
  }, var.tags)

  # Shared diagnostic settings destination. Every AVM module that accepts
  # diagnostic_settings gets this unless the caller overrides per-resource.
  # log_analytics_destination_type never converges on three of them; it is
  # expected noise, not drift. See docs/known-upstream-issues.md.
  law_diagnostic_settings = {
    law = {
      name                           = "diag-law"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = module.log_analytics.resource_id
    }
  }

  # Cosmos AVM only accepts SLI and Requests as metric categories.
  cosmos_diagnostic_settings = {
    law = {
      name                           = "diag-law"
      log_groups                     = ["allLogs"]
      metric_categories              = ["Requests"]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = module.log_analytics.resource_id
    }
  }

  # The storage AVM takes per-service diagnostics in its own schema
  # (logs/metrics objects), not the canonical log_groups/metric_categories
  # interface. Terraform silently drops attributes a target object type does
  # not declare, so law_diagnostic_settings would arrive here as an empty
  # setting and hang the apply for 30 minutes (ADR-0005). Metrics must be
  # listed: blobServices has no AllMetrics pseudo-category.
  storage_blob_diagnostic_settings = {
    law = {
      name = "diag-law"
      logs = [
        { category_group = "allLogs" },
      ]
      metrics = [
        { category = "Transaction" },
        { category = "Capacity" },
      ]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = module.log_analytics.resource_id
    }
  }

  pe_subnet_id  = module.virtual_network.subnets["private_endpoints"].resource_id
  app_subnet_id = module.virtual_network.subnets["app"].resource_id

  # Cheap dev turns PEs off and opens the data plane so a laptop can apply
  # and upload PDFs. Staging/prod keep enable_private_endpoints = true.
  public_data_plane = !var.enable_private_endpoints

  cmk_identity_id = module.workload_identities.ids["cmk"]

  # Customer-managed key block shared by services that speak the AVM CMK
  # interface. Null unless kv_cmk_enabled is true, which also gates the Key
  # Vault key itself (`keys` in main.key-vault.tf) — with CMK off the vault
  # holds no key. Flipping the flag creates the key and rewires every consumer
  # in one apply; it does not recreate the vault.
  cmk = var.kv_cmk_enabled ? {
    key_vault_resource_id = module.key_vault.resource_id
    key_name              = var.kv_cmk_key_name
    user_assigned_identity = {
      resource_id = local.cmk_identity_id
    }
  } : null

  foundry_cmk = var.kv_cmk_enabled ? {
    key_vault_resource_id              = module.key_vault.resource_id
    key_name                           = var.kv_cmk_key_name
    user_assigned_identity_resource_id = local.cmk_identity_id
  } : null

  # AI Search CMK (preview API) only wires the system-assigned identity.
  search_cmk = var.kv_cmk_enabled ? {
    key_vault_resource_id = module.key_vault.resource_id
    key_name              = var.kv_cmk_key_name
  } : null

  sql_tde_key_id = var.kv_cmk_enabled && var.enable_sql ? try(module.key_vault.keys[var.kv_cmk_key_name].resource_id, null) : null
}
