module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  location            = module.rg.location
  name                = var.log_analytics_name
  resource_group_name = module.rg.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  log_analytics_workspace_sku                        = var.log_analytics_sku
  log_analytics_workspace_retention_in_days          = var.log_analytics_retention_in_days
  log_analytics_workspace_internet_ingestion_enabled = var.log_analytics_internet_ingestion_enabled
  log_analytics_workspace_internet_query_enabled     = var.log_analytics_internet_query_enabled
}

# The workspace's own Audit / SummaryLogs / Jobs categories: on a PHI platform,
# who queried the data is itself audit evidence. Standalone rather than the
# module's diagnostic_settings input, because the destination is the workspace
# and that would be a self-reference cycle.
resource "azurerm_monitor_diagnostic_setting" "log_analytics" {
  name                       = "diag-law"
  target_resource_id         = module.log_analytics.resource_id
  log_analytics_workspace_id = module.log_analytics.resource_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
