locals {
  tags = merge({
    workload            = "medical-ai-pipeline"
    environment         = var.environment
    managed_by          = "terraform"
    data_classification = "phi"
  }, var.tags)

  law_diagnostic_settings = {
    law = {
      name                           = "diag-law"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = module.log_analytics.resource_id
    }
  }

  cosmos_diagnostic_settings = {
    law = {
      name                           = "diag-law"
      log_groups                     = ["allLogs"]
      metric_categories              = ["Requests"]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = module.log_analytics.resource_id
    }
  }

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
  public_data_plane = !var.enable_private_endpoints

  cmk_identity_id = module.workload_identities.ids["cmk"]

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

  search_cmk = var.kv_cmk_enabled ? {
    key_vault_resource_id = module.key_vault.resource_id
    key_name              = var.kv_cmk_key_name
  } : null

  sql_tde_key_id = var.kv_cmk_enabled && var.enable_sql ? try(module.key_vault.keys[var.kv_cmk_key_name].resource_id, null) : null
}
