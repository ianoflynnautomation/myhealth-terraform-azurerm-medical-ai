# One-time setup

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | ≥ 1.14 (CI pins 1.15.3) |
| Azure CLI | 2.60+ |
| tflint | 0.53+ |
| terraform-docs | 0.24+ |

You need Owner or User Access Administrator on the subscription (for RBAC
assignments) plus rights to create Cognitive / Search / SQL / Cosmos
resources. Register the resource providers if this is a new subscription:

```bash
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.Search
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ManagedIdentity
```

## Backend

Copy `environments/<env>/example.hcl` to `environments/<env>/backend.hcl`
(gitignored) and point it at an existing Azure Storage account used only for
state. Enable Azure AD auth on that account; this stack sets
`use_azuread_auth = true` and `storage_use_azuread = true`.

Copy `environments/<env>/example.tfvars` to `environments/<env>/terraform.tfvars`
(gitignored). Replace the zeroed subscription ID and globally unique names
(storage, SQL, Cosmos, Search, Document Intelligence subdomain).

After apply, [documents.md](documents.md) is the workflow for blood tests,
surgery notes, and MRI reports.

## First apply (dev)

The **dev example.tfvars is the cheap profile**: no SQL, no Cosmos, no NAT,
no private endpoints, Search free, Document Intelligence F0. Public data
plane is on so a laptop can apply and upload PDFs. Do not copy this profile
to staging or prod.

Staging/prod keep private endpoints. Those data planes are not reachable
from a laptop unless you are on the VNet.

Then:

```bash
az login
az account set --subscription "<subscription-id>"

export ARM_USE_OIDC=false   # laptop uses az login, not OIDC

terraform init -backend-config=environments/dev/backend.hcl
```

### Pass 1 — everything except AI Foundry

A green-field environment is applied **twice**; the reasoning is
[ADR-0006](../adr/0006-two-phase-first-apply-for-foundry-identities.md). The
Foundry pattern module looks up the account's user-assigned identity with a
data source keyed on the identity resource ID, and that ID does not exist
until the identity has been created, so a single-pass plan fails with
`Invalid for_each argument` on
`data.azurerm_user_assigned_identity.ai_foundry_account`.

```bash
make bootstrap ENV=dev
# equivalently:
# terraform apply -var-file=environments/dev/terraform.tfvars -var='enable_foundry=false'
```

This creates the resource group, network, the seven user-assigned identities,
Key Vault, Storage, Document Intelligence, AI Search, and SQL / Cosmos if
enabled — about 95 resources on the dev profile.

### Pass 2 — AI Foundry

```bash
make plan  ENV=dev
make apply ENV=dev ARGS="-parallelism=1"
```

`-parallelism=1` is not optional on a green-field apply: the Foundry model
deployments are a `for_each` map, Azure serialises operations on the parent
Cognitive Services account, and the loser gets
`409 RequestConflict: Another operation is being performed on the parent
resource`. See [ADR-0006](../adr/0006-two-phase-first-apply-for-foundry-identities.md).

The identity resource IDs are known strings in state now, so the lookup
resolves and the Foundry account, project, and model deployments plan
normally. **Every apply after this one is single-pass** — pass 1 is only for a
new environment or one that has been destroyed.

If you would rather keep the first pass minimal,
`terraform apply -target=module.workload_identities` works too; expect
Terraform's partial-state warning.

Revert `kv_public_network_access_enabled` to `false` and re-apply once a
self-hosted runner (or VPN) can reach `privatelink.vaultcore.azure.net`.

Never apply staging or prod from a laptop. Those environments still need the
two passes above on their first run, so the bootstrap is a
`workflow_dispatch` apply with `enable_foundry=false`, not a plan-only step.

### Re-deploying after a destroy

`make destroy` now purges soft-deleted Cognitive Services accounts for you, so
the account name and custom subdomain are reusable at once. Two things still
need care:

- **AI Search** holds its service name in the Search control plane for a while
  after deletion. A redeploy inside that window fails with
  `409 ServiceDeleting`, and no read-only API shows it — `checkNameAvailability`
  will claim the name is free. Just re-run `make bootstrap`, or bump
  `search_name` if you do not want to wait. See
  [ADR-0007](../adr/0007-search-may-run-outside-the-primary-region.md).
- **Key Vault** in dev has purge protection off and 7-day retention, so
  `make purge` removes it outright. Staging and prod keep purge protection, so
  their vaults cannot be purged — the provider recovers them on the next apply
  instead (`recover_soft_deleted_key_vaults = true`).

## After apply

1. Confirm private endpoints show `Approved` and the DNS zones contain A
   records.
2. Grant the pipeline identity to the application repository (annotate the
   workload with `identity_client_ids["pipeline"]`).
3. If SQL is enabled, add the application Entra group as a contained
   database user — the Terraform runner is only the server admin.
4. Check quota for `gpt-4o` and `text-embedding-3-large` in the target
   region before the Foundry deployments succeed.
5. On the cheap-dev profile (`enable_cosmos = false`) the Foundry project is
   created **without** Cosmos, Storage, or Search connections — the pattern
   module treats them as one switch (ADR-0005). Set `enable_cosmos = true` and
   re-apply when the project needs them.
