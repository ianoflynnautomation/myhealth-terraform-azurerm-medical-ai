# ADR-0005: SQL and Cosmos are independently flagged storage tiers

- **Status:** Accepted
- **Date:** 2026-09-20 (amended 2026-10-05: Foundry project connections)
- **Applies to:** `var.enable_sql`, `var.enable_cosmos`, `main.sql.tf`, `main.cosmos.tf`

## Context

Extracted medical JSON has two legitimate homes: a relational store (Azure
SQL, Entra-only auth, TDE, ledger optional) and a document store (Cosmos DB
MongoDB API, autoscale). Some environments want both (SQL for reporting,
Cosmos for the RAG document shape). Some want one.

Hardcoding one store, or switching on `var.environment`, would violate
[ADR-0002](0002-flat-variables-over-object-inputs.md).

## Decision

`enable_sql` and `enable_cosmos` are independent booleans, both defaulting to
`true`. Both may be false: extracted JSON then lives in blob storage and AI
Search only (the cheap-dev profile). SQL is never a Foundry connection.

**Amendment, 2026-10-05.** Foundry project connections cannot be dropped one
at a time. `ai_projects[*].create_project_connections` in
`Azure/avm-ptn-aiml-ai-foundry/azurerm` is a single switch over the Cosmos,
Storage, and Search connections *and* the project role assignments behind
them, and the Cosmos role assignment's `scope` is not optional:

```
Error: Missing required argument
  with module.ai_foundry[0].module.ai_foundry_project["medical"].azurerm_role_assignment.cosmosdb_role_assignments["cosmosdb_operator"],
  on .terraform/modules/ai_foundry/modules/ai-foundry-project/dependent-resource-rbac.tf line 47:
  47:   scope          = var.create_project_connections ? var.cosmos_db_id : "/n/o/t/u/s/e/d"
The argument "scope" is required, but no definition was found.
```

So `local.foundry_project_connections` in `main.ai-foundry.tf` follows
`var.enable_cosmos`: with Cosmos off the project is created with **no**
connections at all, not with Storage and Search connections minus Cosmos.

## Consequences

- Dev can run both; a cost-sensitive sandbox can set `enable_sql = false` in
  tfvars without touching HCL.
- Toggling a flag from true to false **destroys** that store. Do not flip
  this in prod without a data-migration plan.
- With `enable_cosmos = false` the Foundry project has no Storage or Search
  connection either, so RAG wiring inside the Foundry portal has to be done
  by hand (or by the application repo) in that profile. The project, the
  account, and the model deployments are unaffected.
- `foundry_create_ai_agent_service` requires `enable_cosmos = true`; a
  variable validation enforces it rather than letting the capability host
  plan with no thread storage connection.
- AI Search indexers that pointed at the destroyed store must be updated in
  the application repo, not here.

## Alternatives considered

- **A single `storage_tier = "sql" | "cosmos" | "both"` string.** One knob,
  but adding a fourth store later becomes a breaking change. Two booleans
  compose.
- **Always provision both.** Simpler code, higher cost in every environment.
