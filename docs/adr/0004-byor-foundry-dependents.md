# ADR-0004: AI Foundry dependents are brought-your-own, not created by the pattern module

- **Status:** Accepted
- **Date:** 2026-09-20
- **Applies to:** `main.ai-foundry.tf`, `main.key-vault.tf`, `main.storage.tf`, `main.ai-search.tf`, `main.cosmos.tf`

## Context

`Azure/avm-ptn-aiml-ai-foundry/azurerm` can create Key Vault, Storage, Cosmos,
and AI Search for you (CYOR) or consume existing resource IDs (BYOR). CYOR
pins older nested AVM versions, uses Microsoft-managed names, and makes those
four services exist only as an implementation detail of Foundry.

This pipeline needs those four services independently of Foundry: Document
Intelligence writes extracted JSON to Storage; AI Search indexes it for RAG
whether or not a Foundry project is healthy; SQL is not a Foundry dependent
at all.

## Decision

Set `create_byor = false` on the Foundry pattern module. Key Vault, Storage,
AI Search, and Cosmos (when enabled) are first-class root modules. The
Foundry project receives them as `existing_resource_id` connections:

```hcl
ai_search_connection = {
  existing_resource_id = module.ai_search.resource_id
}
```

The pattern module still owns the AI Services account, the project, model
deployments, and the Foundry private endpoint.

## Consequences

- One Key Vault, one storage account, one Search service — not a second copy
  hidden inside Foundry.
- Foundry nested module versions cannot drift from the versions this root
  pins.
- If Microsoft changes the BYOR connection schema, `ai_projects` is the
  blast radius, not the data plane.

## Alternatives considered

- **CYOR (`create_byor = true`).** Faster POC. Rejected: duplicates KV /
  Storage / Search / Cosmos and pins older nested AVM versions.
- **Raw `azurerm_cognitive_account` kind = AIServices instead of the pattern
  module.** More control over the account, but loses project, connections,
  and model-deployment wiring that the pattern module maintains.
