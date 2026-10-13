data "azurerm_client_config" "current" {}

module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = var.resource_group_name
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

resource "terraform_data" "search_free_requires_public_access" {
  lifecycle {
    precondition {
      condition     = var.search_sku != "free" || !var.enable_private_endpoints
      error_message = "Azure AI Search free SKU does not support private endpoints. Set enable_private_endpoints = false, or use search_sku = \"basic\" or higher."
    }
  }
}
