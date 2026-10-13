module "identity" {
  for_each = var.identities
  source   = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version  = "0.5.2"

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  federated_identity_credentials = each.value.federated_identity_credentials
  role_assignments               = each.value.role_assignments
}
