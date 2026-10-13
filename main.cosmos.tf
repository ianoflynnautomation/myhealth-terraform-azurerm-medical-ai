locals {
  cosmos_private_endpoints = var.enable_private_endpoints ? {
    mongo = {
      subnet_resource_id            = local.pe_subnet_id
      subresource_name              = "MongoDB"
      private_dns_zone_resource_ids = [module.private_dns_zones["cosmos_mongo"].resource_id]
      tags                          = local.tags
    }
  } : {}

  cosmos_role_assignments = {
    pipeline_contributor = {
      role_definition_id_or_name = "DocumentDB Account Contributor"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
    foundry_contributor = {
      role_definition_id_or_name = "DocumentDB Account Contributor"
      principal_id               = module.workload_identities.principal_ids["foundry"]
    }
  }

  cosmos_mongo_databases = {
    medical = {
      name = var.cosmos_database_name
      autoscale_settings = {
        max_throughput = var.cosmos_autoscale_max_throughput
      }
      collections = {
        records = {
          name      = var.cosmos_collection_name
          shard_key = var.cosmos_shard_key
          index = {
            keys   = ["_id"]
            unique = true
          }
        }
      }
    }
  }

  cosmos_geo_locations = [
    {
      location          = var.location
      failover_priority = 0
      zone_redundant    = var.cosmos_zone_redundant
    }
  ]
}

module "cosmos" {
  count = var.enable_cosmos ? 1 : 0

  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.11.0"

  location            = module.rg.location
  name                = var.cosmos_account_name
  resource_group_name = module.rg.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  mongo_server_version = var.cosmos_mongo_server_version
  capabilities = [
    { name = "EnableMongo" },
    { name = "EnableMongo16MBDocumentSupport" },
    { name = "EnableMongoRetryableWrites" },
  ]

  public_network_access_enabled         = local.public_data_plane || var.cosmos_public_network_access_enabled
  local_authentication_disabled         = true
  minimal_tls_version                   = "Tls12"
  automatic_failover_enabled            = var.cosmos_automatic_failover_enabled
  multiple_write_locations_enabled      = false
  network_acl_bypass_for_azure_services = true
  ip_range_filter                       = []
  geo_locations                         = local.cosmos_geo_locations
  consistency_policy = {
    consistency_level = var.cosmos_consistency_level
  }
  backup = {
    type = "Continuous"
    tier = var.cosmos_backup_tier
  }

  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = toset([
      module.workload_identities.ids["cosmos"],
      local.cmk_identity_id,
    ])
  }

  customer_managed_key = local.cmk
  mongo_databases      = local.cosmos_mongo_databases
  private_endpoints    = local.cosmos_private_endpoints
  diagnostic_settings  = local.cosmos_diagnostic_settings
  role_assignments     = local.cosmos_role_assignments
}
