subscription_id     = "00000000-0000-0000-0000-000000000000"
resource_group_name = "rg-medai-staging-weu-01"
environment         = "staging"
location            = "westeurope"
location_short_name = "weu"

enable_sql               = true
enable_cosmos            = true
enable_nat_gateway       = true
enable_private_endpoints = true
kv_cmk_enabled           = true

vnet_name                                = "vnet-medai-staging-weu-01"
vnet_address_space                       = ["10.60.0.0/16"]
app_subnet_address_prefixes              = ["10.60.0.0/20"]
private_endpoint_subnet_address_prefixes = ["10.60.16.0/24"]

log_analytics_name              = "law-medai-staging-weu-01"
log_analytics_retention_in_days = 90

kv_name     = "kv-medai-staging-weu-01"
kv_sku_name = "premium"

storage_account_name     = "stmedaistagingweu01"
storage_replication_type = "ZRS"

document_intelligence_name                  = "di-medai-staging-weu-01"
document_intelligence_custom_subdomain_name = "di-medai-staging-weu-01"
document_intelligence_sku                   = "S0"

search_name                = "srch-medai-staging-weu-01"
search_sku                 = "standard"
search_semantic_search_sku = "standard"
search_replica_count       = 2

sql_server_name             = "sql-medai-staging-weu-01"
sql_database_sku_name       = "GP_Gen5_2"
sql_database_zone_redundant = true

cosmos_account_name             = "cosmos-medai-staging-weu-01"
cosmos_autoscale_max_throughput = 4000
cosmos_zone_redundant           = true
cosmos_backup_tier              = "Continuous30Days"

foundry_base_name = "medai"
foundry_name      = "aif-medai-staging-weu-01"

kv_network_acls = {
  bypass                     = "AzureServices"
  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = []
}

tags = {
  owner = "platform"
}
