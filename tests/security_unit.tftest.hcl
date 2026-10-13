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
  enable_foundry                              = false
  enable_telemetry                            = false
}

run "defaults_disable_public_network_access" {
  command = plan

  assert {
    condition     = var.enable_private_endpoints == true
    error_message = "Private endpoints must default to true (ADR-0003). Cheap dev turns them off in tfvars."
  }

  assert {
    condition     = var.kv_public_network_access_enabled == false
    error_message = "Key Vault public network access must default to false (ADR-0003)."
  }

  assert {
    condition     = var.storage_public_network_access_enabled == false
    error_message = "Storage public network access must default to false."
  }

  assert {
    condition     = var.document_intelligence_public_network_access_enabled == false
    error_message = "Document Intelligence public network access must default to false."
  }

  assert {
    condition     = var.search_public_network_access_enabled == false
    error_message = "AI Search public network access must default to false."
  }

  assert {
    condition     = var.sql_public_network_access_enabled == false
    error_message = "SQL public network access must default to false."
  }

  assert {
    condition     = var.cosmos_public_network_access_enabled == false
    error_message = "Cosmos public network access must default to false."
  }

  assert {
    condition     = var.foundry_public_network_access_enabled == false
    error_message = "Foundry public network access must default to false."
  }
}

run "tls_minimum_is_1_2" {
  command = plan

  assert {
    condition     = var.storage_min_tls_version == "TLS1_2"
    error_message = "Storage must default to TLS 1.2."
  }
}

run "fails_when_kv_name_is_invalid" {
  command = plan

  variables {
    kv_name = "bad--name"
  }

  expect_failures = [
    var.kv_name,
  ]
}
