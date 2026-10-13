# Architecture decision records

Decisions that are load-bearing for this stack. Several settings look like
security findings and are deliberate; the ADR is where the reasoning lives.

| ADR | Title |
|---|---|
| [0001](0001-adopt-azure-verified-modules.md) | Provision Azure resources through Azure Verified Modules |
| [0002](0002-flat-variables-over-object-inputs.md) | Root module inputs are flat variables, never grouped objects |
| [0003](0003-private-data-plane-by-default.md) | Private data plane by default; no public PaaS endpoints |
| [0004](0004-byor-foundry-dependents.md) | AI Foundry dependents are brought-your-own, not created by the pattern module |
| [0005](0005-storage-tier-sql-and-cosmos-flags.md) | SQL and Cosmos are independently flagged storage tiers |
| [0006](0006-two-phase-first-apply-for-foundry-identities.md) | A green-field environment is applied twice, Foundry last |
| [0007](0007-search-may-run-outside-the-primary-region.md) | AI Search may run outside the primary region |
| [0008](0008-ai-search-runs-on-its-system-assigned-identity.md) | AI Search runs on its system-assigned identity |

Start a new record from [0000-template.md](0000-template.md).
