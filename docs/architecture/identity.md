# Identity

Every service-to-service call uses a **user-assigned managed identity**, with
one module-driven exception: **AI Search runs on its system-assigned identity**
because `avm-res-search-searchservice` cannot attach a user-assigned one — see
[ADR-0008](../adr/0008-ai-search-runs-on-its-system-assigned-identity.md). API
keys, storage account keys, and SQL passwords are disabled everywhere.

## Identities

| Key | Used by | Typical roles |
|---|---|---|
| `pipeline` | Extraction worker / orchestrator | Storage Blob Data Contributor, Cognitive Services User, Search Index Data Contributor, SQL DB Contributor, Cosmos contributor, Key Vault Secrets User |
| `document_intelligence` | Document Intelligence account | Storage Blob Data Contributor (read PDFs), Key Vault Crypto Service Encryption User |
| `foundry` | AI Foundry account | Storage Blob Data Contributor, Search Service Contributor, Search Index Data Contributor, Cosmos contributor, Cognitive Services OpenAI User, Key Vault Secrets User |
| `search` | **Nothing — unattached.** Kept only so [ADR-0008](../adr/0008-ai-search-runs-on-its-system-assigned-identity.md) can be reverted without minting a new principal | none |
| `sql` | Azure SQL (TDE CMK) | Key Vault Crypto Service Encryption User |
| `cosmos` | Cosmos (CMK) | Key Vault Crypto Service Encryption User |
| `cmk` | Attached to every CMK consumer | Key Vault Crypto Service Encryption User |

Client IDs are exported as `identity_client_ids`. Annotate the application
workload with the `pipeline` client ID (or federate a GitHub environment to
it later).

## AI Search

AI Search is the one service whose grants target a **system-assigned**
principal, exposed as `local.search_principal_id` and applied from
`main.security.tf`:

| Scope | Role |
|---|---|
| Storage account | Storage Blob Data Reader |
| Key Vault | Key Vault Crypto Service Encryption User (only when `kv_cmk_enabled`) |
| SQL server | Reader, SQL DB Contributor (only when `enable_sql`) |
| Cosmos account | Reader, DocumentDB Account Contributor (only when `enable_cosmos`) |

That principal is created with the service, so it changes if the service is
recreated — which changing `search_location` does
([ADR-0007](../adr/0007-search-may-run-outside-the-primary-region.md)).
Terraform-managed grants follow automatically; hand-made ones will not.

## SQL authentication

`azuread_authentication_only = true`. There is no SQL login. The Entra admin
defaults to the Terraform runner's object ID; override
`sql_azuread_admin_object_id` / `sql_azuread_admin_login_username` with a
break-glass group in prod.

## Adding a federated credential

`modules/workload-identities` already accepts
`federated_identity_credentials` per identity. To let GitHub Actions assume
`pipeline`, add an FIC in `main.identity.tf` with issuer
`https://token.actions.githubusercontent.com` and a
`repo:ORG/REPO:environment:ENV` subject — do not put a client secret in CI.
