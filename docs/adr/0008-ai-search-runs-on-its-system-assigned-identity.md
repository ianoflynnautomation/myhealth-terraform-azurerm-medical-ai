# ADR-0008: AI Search runs on its system-assigned identity

- **Status:** Accepted
- **Date:** 2026-10-12
- **Applies to:** `main.ai-search.tf`, `main.security.tf`, `docs/architecture/identity.md`, `modules/workload-identities`

## Context

[identity.md](../architecture/identity.md) states that every service-to-service
call in this stack runs on a user-assigned managed identity, and
`main.ai-search.tf` duly attached the `search` and `cmk` identities to the
Search service. It had no effect. `Azure/avm-res-search-searchservice/azurerm`
0.3.0 hardcodes the identity block:

```hcl
# .terraform/modules/ai_search/main.tf
dynamic "identity" {
  for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? { this = var.managed_identities } : {}

  content {
    # only SystemAssigned is supported
    type = identity.value.system_assigned ? "SystemAssigned" : null
  }
}
```

`user_assigned_resource_ids` is declared, documented, accepted — and never
read. Terraform reports no drift, because the module never tracked the value
in the first place. The live service confirmed it:

```
identity.type       : SystemAssigned
userAssignedIds     : NONE
```

The result was a service with no usable identity for its own permissions:

```
search UAMI  -> Storage Blob Data Reader on the storage account
                            Key Vault Crypto Service Encryption User
search SMI   -> no role assignments at all
```

The identity holding the grants was not attached, and the attached identity had
no grants. AI Search could not read the blob container it is supposed to index,
so the RAG path was broken in a way that no `terraform plan` would ever show.
`local.search_cmk` already carried a comment that Search's CMK only wires the
system identity, so half of this was known.

## Decision

The Search service is declared `system_assigned = true` with no user-assigned
identities, and every Search grant targets that principal through
`local.search_principal_id` (`one(module.ai_search.resource.identity).principal_id`).

All six grants live in `main.security.tf` rather than in each target module's
`role_assignments`. The Key Vault one has to: `module.ai_search` consumes
`module.key_vault` for CMK, so granting from inside the Key Vault module would
be a dependency cycle. Keeping the rest alongside it makes Search's real access
reviewable in one place.

This is a **narrow, module-driven exception** to identity.md, not a reversal.
Every other service in the stack still runs on a user-assigned identity —
Document Intelligence, which is managed through `azapi_resource` by a different
AVM module, correctly shows `type: UserAssigned` with both identities attached.

## Consequences

- Search's permissions are no longer silently inert. The grants and the
  identity finally refer to the same principal.
- The `search` entry in `modules/workload-identities` is now **unreferenced**:
  nothing attaches it and nothing grants to it. It is deliberately left in
  place rather than destroyed, so that the moment the upstream module learns to
  wire user-assigned identities this ADR can be reverted without minting a new
  principal and re-granting. Remove it from `main.identity.tf` if you would
  rather not carry an unused identity — it is one map entry and its
  `search_identity_name_prefix` variable.
- The system-assigned principal is created with the service, so it **changes if
  the service is ever recreated** — which `search_location` changes do
  ([ADR-0007](0007-search-may-run-outside-the-primary-region.md)). The grants
  are Terraform-managed and follow automatically; anything granted by hand
  outside this repo will not.
- `kv_cmk_enabled = false` now means Search holds no Key Vault role at all. The
  previous unconditional grant was broader than needed; `search_cmk_crypto_user`
  is gated on the flag that creates the key.

## Alternatives considered

- **Keep attaching the UAMI and grant both principals.** Hides the bug and
  leaves an identity that looks load-bearing in a security review but is not
  attached to anything. Rejected.
- **Fork or pin forward the Search module.** `0.3.0` is the current release and
  ADR-0001 forbids `git::` sources. The upstream fix is to honour
  `user_assigned_resource_ids` in the identity block; until then there is
  nothing to bump to.
- **Raw `azurerm_search_service` instead of the AVM module.** Full control of
  the identity block, at the cost of re-implementing private endpoints,
  diagnostics, and RBAC wiring that the module already maintains
  ([ADR-0001](0001-adopt-azure-verified-modules.md)).
