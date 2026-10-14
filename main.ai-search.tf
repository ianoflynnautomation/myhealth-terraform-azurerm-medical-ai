locals {
  search_principal_id = one(module.ai_search.resource.identity).principal_id

  search_private_endpoints = var.enable_private_endpoints ? {
    search = {
      subnet_resource_id            = local.pe_subnet_id
      private_dns_zone_resource_ids = [module.private_dns_zones["search"].resource_id]
      tags                          = local.tags
    }
  } : {}

  search_role_assignments = {
    pipeline_index_contributor = {
      role_definition_id_or_name = "Search Index Data Contributor"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
    foundry_index_contributor = {
      role_definition_id_or_name = "Search Index Data Contributor"
      principal_id               = module.workload_identities.principal_ids["foundry"]
    }
    pipeline_service_contributor = {
      role_definition_id_or_name = "Search Service Contributor"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
  }
}

module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.3.0"

  location            = coalesce(var.search_location, module.rg.location)
  name                = var.search_name
  resource_group_name = module.rg.name
  sku                 = var.search_sku
  replica_count       = var.search_replica_count
  partition_count     = var.search_partition_count
  semantic_search_sku = var.search_semantic_search_sku
  hosting_mode        = var.search_hosting_mode

  local_authentication_enabled  = false
  public_network_access_enabled = local.public_data_plane || var.search_public_network_access_enabled
  network_rule_bypass_option    = "AzureServices"
  enable_telemetry              = var.enable_telemetry
  tags                          = local.tags

  managed_identities = {
    system_assigned = true
  }

  customer_managed_key                     = local.search_cmk
  customer_managed_key_enforcement_enabled = var.kv_cmk_enabled
  diagnostic_settings                      = local.law_diagnostic_settings
  private_endpoints                        = local.search_private_endpoints
  role_assignments                         = local.search_role_assignments
}
