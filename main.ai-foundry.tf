locals {
  foundry_project_key = "medical"

  foundry_project_connections = var.enable_cosmos

  foundry_role_assignments = {
    pipeline_user = {
      role_definition_id_or_name = "Cognitive Services User"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
    pipeline_openai_user = {
      role_definition_id_or_name = "Cognitive Services OpenAI User"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
  }
}

module "ai_foundry" {
  count = var.enable_foundry ? 1 : 0

  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.11.3"

  base_name                  = var.foundry_base_name
  location                   = module.rg.location
  resource_group_resource_id = module.rg.resource_id
  enable_telemetry           = var.enable_telemetry
  tags                       = local.tags

  create_byor                              = false
  create_private_endpoints                 = var.enable_private_endpoints
  private_endpoint_subnet_resource_id      = var.enable_private_endpoints ? local.pe_subnet_id : null
  private_endpoint_resource_group_name     = module.rg.name
  private_endpoint_resource_group_location = module.rg.location
  private_endpoints_manage_dns_zone_groups = var.enable_private_endpoints

  diagnostic_settings = local.law_diagnostic_settings

  resource_names = {
    ai_foundry                      = var.foundry_name
    ai_foundry_project              = var.foundry_project_name
    ai_foundry_project_display_name = var.foundry_project_display_name
  }

  ai_foundry = {
    name                          = var.foundry_name
    sku                           = var.foundry_sku
    disable_local_auth            = true
    allow_project_management      = true
    create_ai_agent_service       = var.foundry_create_ai_agent_service
    public_network_access_enabled = local.public_data_plane || var.foundry_public_network_access_enabled
    private_dns_zone_resource_ids = var.enable_private_endpoints ? [
      module.private_dns_zones["cognitiveservices"].resource_id,
      module.private_dns_zones["openai"].resource_id,
      module.private_dns_zones["ai_services"].resource_id,
    ] : []
    network_acls = {
      default_action = local.public_data_plane ? "Allow" : "Deny"
      bypass         = "AzureServices"
    }
    
    managed_identities = {
      system_assigned = false
      user_assigned_resource_ids = toset([
        module.workload_identities.ids["foundry"],
      ])
    }
    customer_managed_key = local.foundry_cmk
    role_assignments     = local.foundry_role_assignments
  }

  ai_projects = {
    (local.foundry_project_key) = {
      name                       = var.foundry_project_name
      display_name               = var.foundry_project_display_name
      description                = var.foundry_project_description
      create_project_connections = local.foundry_project_connections
      cosmos_db_connection = var.enable_cosmos ? {
        existing_resource_id = module.cosmos[0].resource_id
      } : {}
      ai_search_connection = {
        existing_resource_id = module.ai_search.resource_id
      }
      key_vault_connection = {
        existing_resource_id = module.key_vault.resource_id
      }
      storage_account_connection = {
        existing_resource_id = module.storage.resource_id
      }
    }
  }

  ai_model_deployments = var.foundry_model_deployments
}
