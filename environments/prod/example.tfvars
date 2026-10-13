subscription_id     = "00000000-0000-0000-0000-000000000000"
resource_group_name = "rg-medai-prod-weu-01"
environment         = "prod"
location            = "westeurope"
location_short_name = "weu"

enable_sql               = true
enable_cosmos            = true
enable_nat_gateway       = true
enable_private_endpoints = true
kv_cmk_enabled           = true

vnet_name                                = "vnet-medai-prod-weu-01"
vnet_address_space                       = ["10.70.0.0/16"]
app_subnet_address_prefixes              = ["10.70.0.0/20"]
private_endpoint_subnet_address_prefixes = ["10.70.16.0/24"]
nat_gateway_sku_name                     = "StandardV2"

log_analytics_name              = "law-medai-prod-weu-01"
log_analytics_retention_in_days = 365

kv_name                       = "kv-medai-prod-weu-01"
kv_sku_name                   = "premium"
kv_soft_delete_retention_days = 90

storage_account_name     = "stmedaiprodweu01"
storage_replication_type = "GZRS"

document_intelligence_name                  = "di-medai-prod-weu-01"
document_intelligence_custom_subdomain_name = "di-medai-prod-weu-01"
document_intelligence_sku                   = "S0"

search_name                = "srch-medai-prod-weu-01"
search_sku                 = "standard"
search_semantic_search_sku = "standard"
search_replica_count       = 3
search_partition_count     = 1

sql_server_name                        = "sql-medai-prod-weu-01"
sql_database_sku_name                  = "GP_Gen5_4"
sql_database_max_size_gb               = 256
sql_database_zone_redundant            = true
sql_database_storage_account_type      = "GeoZone"
sql_database_short_term_retention_days = 35
sql_audit_retention_in_days            = 90

cosmos_account_name             = "cosmos-medai-prod-weu-01"
cosmos_autoscale_max_throughput = 10000
cosmos_zone_redundant           = true
cosmos_backup_tier              = "Continuous30Days"

foundry_base_name = "medai"
foundry_name      = "aif-medai-prod-weu-01"

kv_network_acls = {
  bypass                     = "AzureServices"
  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = []
}

tags = {
  owner = "platform"
}
