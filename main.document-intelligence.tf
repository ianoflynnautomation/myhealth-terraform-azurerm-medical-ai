locals {
  document_intelligence_private_endpoints = var.enable_private_endpoints ? {
    account = {
      subnet_resource_id            = local.pe_subnet_id
      private_dns_zone_resource_ids = [module.private_dns_zones["cognitiveservices"].resource_id]
      tags                          = local.tags
    }
  } : {}

  document_intelligence_role_assignments = {
    pipeline_user = {
      role_definition_id_or_name = "Cognitive Services User"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
    foundry_user = {
      role_definition_id_or_name = "Cognitive Services User"
      principal_id               = module.workload_identities.principal_ids["foundry"]
    }
  }
}

module "document_intelligence" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.1"

  kind                               = "FormRecognizer"
  location                           = module.rg.location
  name                               = var.document_intelligence_name
  parent_id                          = module.rg.resource_id
  sku_name                           = var.document_intelligence_sku
  custom_subdomain_name              = var.document_intelligence_custom_subdomain_name
  local_auth_enabled                 = false
  public_network_access_enabled      = local.public_data_plane || var.document_intelligence_public_network_access_enabled
  outbound_network_access_restricted = var.document_intelligence_outbound_network_access_restricted
  enable_telemetry                   = var.enable_telemetry
  tags                               = local.tags

  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = toset([
      module.workload_identities.ids["document_intelligence"],
      local.cmk_identity_id,
    ])
  }

  customer_managed_key = local.cmk
  diagnostic_settings  = local.law_diagnostic_settings
  private_endpoints    = local.document_intelligence_private_endpoints
  role_assignments     = local.document_intelligence_role_assignments

  # No `bypass`: the FormRecognizer kind rejects trusted-services bypass with
  # 400 NetworkAclsBypassNotSupported, so there is nothing to trade away.
  # Other Cognitive kinds, including the Foundry account, do accept it.
  network_acls = {
    default_action = local.public_data_plane ? "Allow" : "Deny"
  }

  storage = var.document_intelligence_byo_storage_enabled ? [{
    storage_account_id = module.storage.resource_id
    identity_client_id = module.workload_identities.client_ids["document_intelligence"]
  }] : null
}
