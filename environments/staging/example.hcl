resource_group_name  = "rg-state-shared-weu-01"
storage_account_name = "sttfstatesharedweu01"
container_name       = "tfstate"
key                  = "staging.tfstate"
use_oidc             = true
use_azuread_auth     = true
