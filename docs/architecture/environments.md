# Environments

One root module. Three directories under `environments/`. No workspaces. No
per-environment HCL.

| | dev (cheap) | staging | prod |
|---|---|---|---|
| Address space (example) | 10.50.0.0/16 | 10.60.0.0/16 | 10.70.0.0/16 |
| SQL / Cosmos | off | on | on |
| NAT Gateway / private endpoints | off (public data plane) | on | on |
| Storage replication | LRS | ZRS | GZRS |
| Search SKU | free | standard (2 replicas) | standard (3 replicas) |
| Document Intelligence | F0 (500 pages/month) | S0 | S0 |
| SQL SKU | — | GP_Gen5_2 | GP_Gen5_4 |
| KV SKU / CMK | standard / off | premium / on | premium / on |
| LAW retention | 30 | 90 | 365 |
| Idle cost (ballpark) | a few $/month + usage | $200–900 | $900+ |
| Promotion | — | after a green dev apply | after a green staging apply |

State keys are `dev.tfstate` / `staging.tfstate` / `prod.tfstate` in the same
backend storage account, Azure AD auth, OIDC.

Staging and prod apply through `workflow_dispatch` with GitHub Environment
reviewers, never from a laptop.
