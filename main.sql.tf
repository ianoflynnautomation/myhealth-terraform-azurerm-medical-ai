locals {
  sql_azuread_administrator = {
    azuread_authentication_only = true
    login_username              = coalesce(var.sql_azuread_admin_login_username, "terraform")
    object_id                   = coalesce(var.sql_azuread_admin_object_id, data.azurerm_client_config.current.object_id)
    tenant_id                   = data.azurerm_client_config.current.tenant_id
  }

  sql_private_endpoints = var.enable_private_endpoints ? {
    sql = {
      subnet_resource_id            = local.pe_subnet_id
      subresource_name              = "sqlServer"
      private_dns_zone_resource_ids = [module.private_dns_zones["sql"].resource_id]
      tags                          = local.tags
    }
  } : {}

  sql_role_assignments = {
    pipeline_contributor = {
      role_definition_id_or_name = "SQL DB Contributor"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
  }

  sql_databases = {
    medical = {
      name                                = var.sql_database_name
      sku_name                            = var.sql_database_sku_name
      max_size_gb                         = var.sql_database_max_size_gb
      collation                           = var.sql_database_collation
      min_capacity                        = var.sql_database_min_capacity
      auto_pause_delay_in_minutes         = var.sql_database_auto_pause_delay_in_minutes
      zone_redundant                      = var.sql_database_zone_redundant
      ledger_enabled                      = var.sql_database_ledger_enabled
      storage_account_type                = var.sql_database_storage_account_type
      transparent_data_encryption_enabled = true
      short_term_retention_policy = {
        retention_days           = var.sql_database_short_term_retention_days
        backup_interval_in_hours = 24
      }
    }
  }
}

module "sql" {
  count = var.enable_sql ? 1 : 0

  source  = "Azure/avm-res-sql-server/azurerm"
  version = "0.2.1"

  location            = module.rg.location
  name                = var.sql_server_name
  resource_group_name = module.rg.name
  server_version      = var.sql_server_version
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  azuread_administrator                        = local.sql_azuread_administrator
  public_network_access_enabled                = local.public_data_plane || var.sql_public_network_access_enabled
  express_vulnerability_assessment_enabled     = var.sql_express_vulnerability_assessment_enabled
  connection_policy                            = var.sql_connection_policy
  transparent_data_encryption_key_vault_key_id = var.kv_cmk_enabled ? try(module.key_vault.keys[var.kv_cmk_key_name].id, null) : null

  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = toset([
      module.workload_identities.ids["sql"],
      local.cmk_identity_id,
    ])
  }
  primary_user_assigned_identity_id = module.workload_identities.ids["sql"]

  databases           = local.sql_databases
  private_endpoints   = local.sql_private_endpoints
  diagnostic_settings = local.law_diagnostic_settings
  role_assignments    = local.sql_role_assignments
}

resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  count = var.enable_sql ? 1 : 0

  server_id              = module.sql[0].resource_id
  enabled                = true
  log_monitoring_enabled = true
  retention_in_days      = var.sql_audit_retention_in_days
}

resource "azurerm_mssql_server_security_alert_policy" "this" {
  count = var.enable_sql ? 1 : 0

  resource_group_name  = module.rg.name
  server_name          = var.sql_server_name
  state                = "Enabled"
  email_account_admins = var.sql_security_alert_email_account_admins
  email_addresses      = var.sql_security_alert_email_addresses
  retention_days       = var.sql_audit_retention_in_days
}
