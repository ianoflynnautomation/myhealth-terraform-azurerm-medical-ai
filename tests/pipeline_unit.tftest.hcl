mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      client_id       = "22222222-2222-2222-2222-222222222222"
      object_id       = "33333333-3333-3333-3333-333333333333"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}



override_module {
  target = module.rg
  outputs = {
    name        = "rg-medai-test-weu-01"
    location    = "westeurope"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01"
  }
}

override_module {
  target = module.nat_gateway
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Network/natGateways/natgw-dev-weu"
  }
}

override_module {
  target = module.virtual_network
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-medai-test-weu-01"
    subnets = {
      app = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-medai-test-weu-01/subnets/AppSubnet"
      }
      private_endpoints = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-medai-test-weu-01/subnets/PrivateEndpointSubnet"
      }
    }
  }
}

override_module {
  target = module.private_dns_zones
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Network/privateDnsZones/placeholder"
  }
}

override_module {
  target = module.log_analytics
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.OperationalInsights/workspaces/law-medai-test-weu-01"
  }
}

override_module {
  target = module.workload_identities
  outputs = {
    ids = {
      pipeline              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-pipeline"
      document_intelligence = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-di"
      foundry               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-foundry"
      search                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-search"
      sql                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sql"
      cosmos                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cosmos"
      cmk                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cmk"
    }
    client_ids = {
      pipeline              = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"
      document_intelligence = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2"
      foundry               = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3"
      search                = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4"
      sql                   = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5"
      cosmos                = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6"
      cmk                   = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa7"
    }
    principal_ids = {
      pipeline              = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1"
      document_intelligence = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2"
      foundry               = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb3"
      search                = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb4"
      sql                   = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb5"
      cosmos                = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb6"
      cmk                   = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb7"
    }
    names = {
      pipeline              = "id-medai-pipeline-dev-weu"
      document_intelligence = "id-medai-di-dev-weu"
      foundry               = "id-medai-foundry-dev-weu"
      search                = "id-medai-search-dev-weu"
      sql                   = "id-medai-sql-dev-weu"
      cosmos                = "id-medai-cosmos-dev-weu"
      cmk                   = "id-medai-cmk-dev-weu"
    }
  }
}

override_module {
  target = module.key_vault
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.KeyVault/vaults/kv-medai-test-weu-01"
    uri         = "https://kv-medai-test-weu-01.vault.azure.net/"
    keys = {
      "cmk-medical-pipeline" = {
        id = "https://kv-medai-test-weu-01.vault.azure.net/keys/cmk-medical-pipeline/version"
      }
    }
  }
}

override_module {
  target = module.storage
  outputs = {
    name        = "stmedaitestweu01"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Storage/storageAccounts/stmedaitestweu01"
  }
}

override_module {
  target = module.document_intelligence
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.CognitiveServices/accounts/di-medai-test-weu-01"
  }
}

override_module {
  target = module.ai_search
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Search/searchServices/srch-medai-test-weu-01"
    # local.search_principal_id reads the system-assigned principal off the
    # full resource output, because the module cannot attach a user-assigned
    # identity (ADR-0008).
    resource = {
      identity = [{
        type         = "SystemAssigned"
        principal_id = "44444444-4444-4444-4444-444444444444"
      }]
    }
  }
}

override_module {
  target = module.sql
  outputs = {
    resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.Sql/servers/sql-medai-test-weu-01"
    resource_name = "sql-medai-test-weu-01"
  }
}

override_module {
  target = module.cosmos
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-medai-test-weu-01/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-medai-test-weu-01"
  }
}

variables {
  subscription_id                             = "00000000-0000-0000-0000-000000000000"
  resource_group_name                         = "rg-medai-test-weu-01"
  environment                                 = "dev"
  location                                    = "westeurope"
  location_short_name                         = "weu"
  vnet_name                                   = "vnet-medai-test-weu-01"
  vnet_address_space                          = ["10.50.0.0/16"]
  log_analytics_name                          = "law-medai-test-weu-01"
  kv_name                                     = "kv-medai-test-weu-01"
  storage_account_name                        = "stmedaitestweu01"
  document_intelligence_name                  = "di-medai-test-weu-01"
  document_intelligence_custom_subdomain_name = "di-medai-test-weu-01"
  search_name                                 = "srch-medai-test-weu-01"
  sql_server_name                             = "sql-medai-test-weu-01"
  cosmos_account_name                         = "cosmos-medai-test-weu-01"
  foundry_name                                = "aif-medai-test-weu-01"
  # Nested Foundry AVM uses ephemeral azapi resources the mock provider cannot plan.
  enable_foundry   = false
  enable_telemetry = false
}

run "plans_with_both_storage_tiers" {
  command = plan

  assert {
    condition     = module.rg.name == "rg-medai-test-weu-01"
    error_message = "Resource group name should come from the overridden module."
  }

  assert {
    condition     = output.search_endpoint == "https://srch-medai-test-weu-01.search.windows.net"
    error_message = "Search endpoint should be derived from search_name."
  }

  assert {
    condition     = output.document_intelligence_endpoint == "https://di-medai-test-weu-01.cognitiveservices.azure.com/"
    error_message = "Document Intelligence endpoint should use the custom subdomain."
  }
}

run "fails_when_environment_is_invalid" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [
    var.environment,
  ]
}

run "plans_cheap_dev_without_sql_cosmos_or_nat" {
  command = plan

  variables {
    enable_sql                 = false
    enable_cosmos              = false
    enable_nat_gateway         = false
    enable_private_endpoints   = false
    kv_cmk_enabled             = false
    search_sku                 = "free"
    search_semantic_search_sku = null
  }

  assert {
    condition     = output.sql_server_id == null
    error_message = "SQL must be omitted when enable_sql is false."
  }

  assert {
    condition     = output.cosmos_account_id == null
    error_message = "Cosmos must be omitted when enable_cosmos is false."
  }

  assert {
    condition     = output.nat_gateway_resource_id == null
    error_message = "NAT Gateway must be omitted when enable_nat_gateway is false."
  }
}

run "fails_when_search_free_with_private_endpoints" {
  command = plan

  variables {
    search_sku               = "free"
    enable_private_endpoints = true
  }

  expect_failures = [
    terraform_data.search_free_requires_public_access,
  ]
}

run "plans_sql_only" {
  command = plan

  variables {
    enable_sql    = true
    enable_cosmos = false
  }

  assert {
    condition     = output.sql_server_id != null
    error_message = "SQL server ID should be present when enable_sql is true."
  }
}

run "plans_cosmos_only" {
  command = plan

  variables {
    enable_sql    = false
    enable_cosmos = true
  }

  assert {
    condition     = output.cosmos_account_id != null
    error_message = "Cosmos account ID should be present when enable_cosmos is true."
  }
}

# ADR-0005: the Foundry pattern module wires project connections as one
# switch, and the agent capability host needs the Cosmos thread storage
# connection among them.
run "fails_when_agent_service_enabled_without_cosmos" {
  command = plan

  variables {
    foundry_create_ai_agent_service = true
    enable_cosmos                   = false
  }

  expect_failures = [
    var.foundry_create_ai_agent_service,
  ]
}

run "plans_agent_service_with_cosmos" {
  command = plan

  variables {
    foundry_create_ai_agent_service = true
    enable_cosmos                   = true
  }

  assert {
    condition     = output.cosmos_account_id != null
    error_message = "Cosmos account ID should be present when the agent service is enabled."
  }
}

# ADR-0008: avm-res-search-searchservice silently ignores
# user_assigned_resource_ids, so a grant aimed at a UAMI leaves the service
# with no usable identity and nothing in `terraform plan` shows it. Pin the
# principal to the system-assigned one.
run "search_grants_target_the_system_identity" {
  command = plan

  assert {
    condition     = azurerm_role_assignment.search_reads_blobs.principal_id == "44444444-4444-4444-4444-444444444444"
    error_message = "Search blob access must be granted to the Search system-assigned principal (ADR-0008), not a user-assigned identity."
  }

  assert {
    condition     = azurerm_role_assignment.search_reads_blobs.role_definition_name == "Storage Blob Data Reader"
    error_message = "AI Search must keep read-only access to the extracted-JSON blobs."
  }
}
