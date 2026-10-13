# Cheap personal-dev profile. Copy to terraform.tfvars (gitignored).
#
# Every name containing "example" is globally unique in Azure and must be
# replaced, along with the zeroed subscription ID. The names without it
# (resource group, VNet, workspace) are scoped to the subscription and can be
# kept as-is. Approximate idle cost: a few dollars a month plus Foundry and
# Document Intelligence usage.
#
# Do not copy this profile to staging or prod — it opens the data plane and
# turns off purge protection. See environments/staging/example.tfvars.
subscription_id     = "00000000-0000-0000-0000-000000000000"
resource_group_name = "rg-medai-dev-weu-01"
environment         = "dev"
location            = "swedencentral"
location_short_name = "sdc"

# No SQL, no Cosmos, no NAT gateway, no private endpoints. Public data plane is
# on so a laptop can apply and upload PDFs (ADR-0003 exception, ADR-0005).
# enable_cosmos = false also means the Foundry project is created with no
# connections at all — the pattern module treats them as one switch.
enable_sql               = false
enable_cosmos            = false
enable_nat_gateway       = false
enable_private_endpoints = false
kv_cmk_enabled           = false

vnet_name                                = "vnet-medai-dev-weu-01"
vnet_address_space                       = ["10.50.0.0/16"]
app_subnet_address_prefixes              = ["10.50.0.0/20"]
private_endpoint_subnet_address_prefixes = ["10.50.16.0/24"]

log_analytics_name              = "law-medai-dev-weu-01"
log_analytics_retention_in_days = 30

# Purge protection off and the 7-day minimum retention so dev can be torn down
# completely. Both are immutable after creation, and Azure refuses to disable
# purge protection on an existing vault — a vault created with the staging or
# prod defaults can never be converted. Staging and prod keep the secure
# defaults (ADR-0003).
kv_name                         = "kv-medai-example-weu-01"
kv_sku_name                     = "standard"
kv_purge_protection_enabled     = false
kv_purge_soft_delete_on_destroy = true
kv_soft_delete_retention_days   = 7

storage_account_name     = "stmedaiexampleweu01"
storage_replication_type = "LRS"

# BYOS needs the feature enabled on the subscription and is rejected on F0 with
# 400 BringOwnFeatureNotEnabled.
document_intelligence_name                               = "di-medai-example-weu-01"
document_intelligence_custom_subdomain_name              = "di-medai-example-weu-01"
document_intelligence_sku                                = "F0"
document_intelligence_outbound_network_access_restricted = false
document_intelligence_byo_storage_enabled                = false

# search_location pins Search to its own region because swedencentral has no
# free-tier Search capacity. Leave it null to keep Search with everything else;
# setting it splits data residency, so read ADR-0007 before using it outside
# dev. Region eligibility is not visible through any read-only API — if the
# apply returns InsufficientResourcesAvailable or RequestDisallowedByAzure,
# try northeurope, germanywestcentral, francecentral, uksouth or norwayeast.
search_location            = "northeurope"
search_name                = "srch-medai-example-weu-01"
search_sku                 = "free"
search_semantic_search_sku = null
search_replica_count       = 1
search_partition_count     = 1

sql_server_name       = "sql-medai-example-weu-01"
sql_database_sku_name = "GP_S_Gen5_2"

cosmos_account_name             = "cosmos-medai-example-weu-01"
cosmos_autoscale_max_throughput = 1000

# Capacity 1 per deployment keeps dev inside a default quota. Check quota for
# both models in the target region before applying.
foundry_base_name = "medai"
foundry_name      = "aif-medai-example-weu-01"

foundry_model_deployments = {
  gpt4o = {
    name = "gpt-4o"
    model = {
      format  = "OpenAI"
      name    = "gpt-4o"
      version = "2024-11-20"
    }
    scale = {
      type     = "Standard"
      capacity = 1
    }
  }
  embeddings = {
    name = "text-embedding-3-large"
    model = {
      format  = "OpenAI"
      name    = "text-embedding-3-large"
      version = "1"
    }
    scale = {
      type     = "Standard"
      capacity = 1
    }
  }
}

kv_network_acls = {
  bypass                     = "AzureServices"
  default_action             = "Allow"
  ip_rules                   = []
  virtual_network_subnet_ids = []
}

tags = {
  owner = "platform"
}
