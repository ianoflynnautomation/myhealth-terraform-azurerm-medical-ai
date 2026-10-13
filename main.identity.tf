locals {
  workload_identity_audience = ["api://AzureADTokenExchange"]
}

# One user-assigned identity per service that needs to talk to another
# Azure data plane. Role assignments that target resources created later
# live in main.security.tf to avoid cycles; identities themselves are
# created first so every other module can reference principal_ids.
module "workload_identities" {
  source = "./modules/workload-identities"

  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry

  identities = {
    pipeline = {
      name = "${var.pipeline_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
    document_intelligence = {
      name = "${var.document_intelligence_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
    foundry = {
      name = "${var.foundry_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
    search = {
      name = "${var.search_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
    sql = {
      name = "${var.sql_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
    cosmos = {
      name = "${var.cosmos_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
    cmk = {
      name = "${var.cmk_identity_name_prefix}${var.environment}-${var.location_short_name}"
    }
  }
}
