locals {
  storage_private_endpoints = var.enable_private_endpoints ? {
    blob = {
      subnet_resource_id            = local.pe_subnet_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = [module.private_dns_zones["blob"].resource_id]
      tags                          = local.tags
    }
  } : {}

  storage_role_assignments = {
    pipeline_blob_contributor = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
    document_intelligence_blob_contributor = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = module.workload_identities.principal_ids["document_intelligence"]
    }
    foundry_blob_contributor = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = module.workload_identities.principal_ids["foundry"]
    }
  }
}

module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.10.0"

  name                            = var.storage_account_name
  parent_id                       = module.rg.resource_id
  location                        = module.rg.location
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_replication_type
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = local.public_data_plane || var.storage_public_network_access_enabled
  https_traffic_only_enabled      = true
  min_tls_version                 = var.storage_min_tls_version
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  enable_telemetry                = var.enable_telemetry
  tags                            = local.tags

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = toset([local.cmk_identity_id])
  }

  customer_managed_key = local.cmk

  network_rules = {
    default_action = local.public_data_plane ? "Allow" : "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.storage_ip_rules
  }

  containers = var.storage_containers

  private_endpoints = local.storage_private_endpoints
  role_assignments  = local.storage_role_assignments

  diagnostic_settings_blob = local.storage_blob_diagnostic_settings
}
