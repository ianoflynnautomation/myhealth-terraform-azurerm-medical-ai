locals {
  kv_role_assignments = {
    terraform_runner = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    pipeline_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.workload_identities.principal_ids["pipeline"]
    }
    foundry_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.workload_identities.principal_ids["foundry"]
    }
    cmk_crypto_user = {
      role_definition_id_or_name = "Key Vault Crypto Service Encryption User"
      principal_id               = module.workload_identities.principal_ids["cmk"]
    }
    document_intelligence_crypto_user = {
      role_definition_id_or_name = "Key Vault Crypto Service Encryption User"
      principal_id               = module.workload_identities.principal_ids["document_intelligence"]
    }
    sql_crypto_user = {
      role_definition_id_or_name = "Key Vault Crypto Service Encryption User"
      principal_id               = module.workload_identities.principal_ids["sql"]
    }
    cosmos_crypto_user = {
      role_definition_id_or_name = "Key Vault Crypto Service Encryption User"
      principal_id               = module.workload_identities.principal_ids["cosmos"]
    }
    foundry_crypto_user = {
      role_definition_id_or_name = "Key Vault Crypto Service Encryption User"
      principal_id               = module.workload_identities.principal_ids["foundry"]
    }
  }

  kv_keys = {
    (var.kv_cmk_key_name) = {
      name     = var.kv_cmk_key_name
      key_type = "RSA"
      key_size = 4096
      key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
    }
  }

  kv_private_endpoints = var.enable_private_endpoints ? merge(var.kv_private_endpoints, {
    vault = {
      subnet_resource_id            = local.pe_subnet_id
      private_dns_zone_resource_ids = [module.private_dns_zones["vaultcore"].resource_id]
      tags                          = local.tags
    }
  }) : {}
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"

  location                                = module.rg.location
  name                                    = var.kv_name
  resource_group_name                     = module.rg.name
  tenant_id                               = data.azurerm_client_config.current.tenant_id
  diagnostic_settings                     = local.law_diagnostic_settings
  enable_telemetry                        = var.enable_telemetry
  enabled_for_disk_encryption             = var.kv_enabled_for_disk_encryption
  keys                                    = var.kv_cmk_enabled ? local.kv_keys : {}
  network_acls                            = var.kv_network_acls
  private_endpoints                       = local.kv_private_endpoints
  private_endpoints_manage_dns_zone_group = true
  public_network_access_enabled           = local.public_data_plane || var.kv_public_network_access_enabled
  purge_protection_enabled                = var.kv_purge_protection_enabled
  role_assignments                        = local.kv_role_assignments
  sku_name                                = var.kv_sku_name
  soft_delete_retention_days              = var.kv_soft_delete_retention_days
  tags                                    = local.tags
  wait_for_rbac_before_key_operations     = var.kv_wait_for_rbac_before_key_operations
  wait_for_rbac_before_secret_operations  = var.kv_wait_for_rbac_before_secret_operations
}
