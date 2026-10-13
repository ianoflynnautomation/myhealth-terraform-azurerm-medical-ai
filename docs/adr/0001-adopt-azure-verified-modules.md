# ADR-0001: Provision Azure resources through Azure Verified Modules

- **Status:** Accepted
- **Date:** 2026-09-20
- **Applies to:** every `module` block in the root module that targets an Azure resource

## Context

This stack provisions a resource group, VNet, NAT Gateway, private DNS zones,
Key Vault, storage, Document Intelligence, AI Search, Azure SQL, Cosmos DB,
Log Analytics, user-assigned identities, and Azure AI Foundry. Written as raw
`azurerm_*` resources, each of those carries its own diagnostic settings, role
assignment plumbing, private endpoint wiring, and secure-default choices that
have to be re-derived and re-reviewed every time.

Microsoft publishes [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
covering all of these, with secure defaults, a consistent interface for
`role_assignments` / `private_endpoints` / `diagnostic_settings`, and a
published support commitment. AI Foundry additionally has a pattern module
that creates the account, project, model deployments, and connections.

## Decision

Every heavyweight Azure resource is provisioned through an AVM module, pinned
by registry `source` plus an **exact** `version`:

```hcl
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"
}
```

Currently in use: `avm-res-resources-resourcegroup` 0.4.0,
`avm-res-network-virtualnetwork` 0.22.2, `avm-res-network-natgateway` 0.3.2,
`avm-res-network-privatednszone` 0.5.0, `avm-res-keyvault-vault` 0.11.0,
`avm-res-storage-storageaccount` 0.10.0,
`avm-res-cognitiveservices-account` 0.11.1,
`avm-res-search-searchservice` 0.3.0, `avm-res-sql-server` 0.2.1,
`avm-res-documentdb-databaseaccount` 0.11.0,
`avm-ptn-aiml-ai-foundry` 0.11.3,
`avm-res-operationalinsights-workspace` 0.5.1,
`avm-res-managedidentity-userassignedidentity` 0.5.2.

The local module under `modules/workload-identities/` is a composition wrapper
over the UAMI module with `for_each`. SQL auditing and Defender-for-SQL alert
policies have no AVM surface yet and stay as thin `azurerm_*` resources next
to the SQL module.

Version bumps arrive as Renovate PRs. `renovate.json` never auto-merges a
module PR; AVM modules are pre-1.0, so minor bumps are treated as potentially
breaking.

## Consequences

- Security defaults, role assignment plumbing, and private endpoint wiring are
  maintained upstream rather than here.
- Upgrades become a version bump and a plan review instead of a resource
  rewrite.
- Exact-version pinning (not `~>`) means the plan a reviewer approves is the
  plan that runs. Do not relax these to ranges.

## Alternatives considered

- **Raw `azurerm_*` resources.** Maximum control, but re-derives secure
  defaults for a dozen resource types.
- **`git::` sources pinned to a commit SHA.** Gives content integrity that
  registry sources do not. Rejected: it requires resolving every release tag to
  a SHA by hand.
- **Let `avm-ptn-aiml-ai-foundry` create KV/Storage/Search/Cosmos (CYOR).**
  Rejected in [ADR-0004](0004-byor-foundry-dependents.md).
