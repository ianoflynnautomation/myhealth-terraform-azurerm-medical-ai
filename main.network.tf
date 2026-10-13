locals {
  nat_gateway_name           = coalesce(var.nat_gateway_name, "natgw-${var.environment}-${var.location_short_name}")
  nat_gateway_public_ip_name = coalesce(var.nat_gateway_public_ip_name, "pip-natgw-${var.environment}-${var.location_short_name}")
  nat_gateway_public_ip_sku  = var.nat_gateway_sku_name == "StandardV2" ? "StandardV2" : "Standard"

  # NAT is created first and associated here so the app subnet has egress
  # while default_outbound_access_enabled stays false (no implicit Azure
  # SNAT). The private-endpoint subnet is inbound-only and is not NATed.
  subnets = {
    app = merge(
      {
        name                                          = var.app_subnet_name
        address_prefixes                              = var.app_subnet_address_prefixes
        private_endpoint_network_policies             = "Enabled"
        private_link_service_network_policies_enabled = true
        default_outbound_access_enabled               = !var.enable_nat_gateway
      },
      var.enable_nat_gateway ? {
        nat_gateway = {
          id = module.nat_gateway[0].resource_id
        }
      } : {}
    )
    private_endpoints = {
      name                                          = var.private_endpoint_subnet_name
      address_prefixes                              = var.private_endpoint_subnet_address_prefixes
      private_endpoint_network_policies             = "Disabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
    }
  }

  # One private DNS zone per PaaS private-link hostname. Always created so
  # toggling SQL/Cosmos flags does not recreate zones.
  private_dns_zones = {
    vaultcore = {
      domain_name = "privatelink.vaultcore.azure.net"
    }
    blob = {
      domain_name = "privatelink.blob.core.windows.net"
    }
    cognitiveservices = {
      domain_name = "privatelink.cognitiveservices.azure.com"
    }
    openai = {
      domain_name = "privatelink.openai.azure.com"
    }
    ai_services = {
      domain_name = "privatelink.services.ai.azure.com"
    }
    search = {
      domain_name = "privatelink.search.windows.net"
    }
    sql = {
      domain_name = "privatelink.database.windows.net"
    }
    cosmos_mongo = {
      domain_name = "privatelink.mongo.cosmos.azure.com"
    }
  }
}

module "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"

  location  = module.rg.location
  parent_id = module.rg.resource_id
  name      = local.nat_gateway_name

  sku_name                = var.nat_gateway_sku_name
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
  enable_telemetry        = var.enable_telemetry
  tags                    = local.tags

  public_ips = {
    ip_1 = {
      name = local.nat_gateway_public_ip_name
    }
  }

  public_ip_configuration = {
    ip_1 = {
      sku   = local.nat_gateway_public_ip_sku
      zones = var.nat_gateway_sku_name == "StandardV2" ? ["1", "2", "3"] : null
    }
  }
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.2"

  location            = module.rg.location
  parent_id           = module.rg.resource_id
  address_space       = var.vnet_address_space
  diagnostic_settings = local.law_diagnostic_settings
  enable_telemetry    = var.enable_telemetry
  name                = var.vnet_name
  subnets             = local.subnets
  tags                = local.tags
}

module "private_dns_zones" {
  for_each = var.enable_private_endpoints ? local.private_dns_zones : {}

  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  parent_id        = module.rg.resource_id
  domain_name      = each.value.domain_name
  enable_telemetry = var.enable_telemetry
  tags             = local.tags

  virtual_network_links = {
    pipeline = {
      name                                   = "${each.key}-${var.environment}"
      virtual_network_id                     = module.virtual_network.resource_id
      registration_enabled                   = false
      private_dns_zone_supports_private_link = true
    }
  }
}
