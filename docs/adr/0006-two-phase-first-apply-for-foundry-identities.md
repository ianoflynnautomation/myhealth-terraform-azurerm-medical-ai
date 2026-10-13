# ADR-0006: A green-field environment is applied twice, Foundry last

- **Status:** Accepted
- **Date:** 2026-10-05
- **Applies to:** `main.ai-foundry.tf`, `main.identity.tf`, `var.enable_foundry`, `docs/runbooks/setup.md`, every new environment

## Context

`Azure/avm-ptn-aiml-ai-foundry/azurerm` 0.11.3 resolves the principal IDs of
the identities attached to the Foundry account with a data source keyed on the
identity resource IDs:

```hcl
# .terraform/modules/ai_foundry/data.tf
data "azurerm_user_assigned_identity" "ai_foundry_account" {
  for_each = toset(tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids))

  name                = split("/", each.value)[8]
  resource_group_name = split("/", each.value)[4]
}
```

`for_each` over a set means the keys *are* the values. This repository creates
the identities in the same root module — one user-assigned identity per
service, [docs/architecture/identity.md](../architecture/identity.md) — so on a
green-field apply the resource IDs are unknown until apply and Terraform
refuses to plan:

```
Error: Invalid for_each argument
  on .terraform/modules/ai_foundry/data.tf line 5, in data "azurerm_user_assigned_identity" "ai_foundry_account":
   5:   for_each = toset(tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids))
The "for_each" set includes values derived from resource attributes that
cannot be determined until apply, and so Terraform cannot determine the
full set of keys that will identify the instances of this resource.
```

0.11.3 is the newest published version as of 2026-10-05, and nothing upstream
tracks this: issue #65 on `Azure/terraform-azurerm-avm-ptn-aiml-ai-foundry` is
the closed feature request that *added* the lookup. Note that the data source
feeds only `account_user_assigned_identity_principal_ids`, which the project
module uses exclusively for the Standard Agent Setup role assignments —
`create_ai_agent_service && create_project_connections`. With
`foundry_create_ai_agent_service = false` the lookup is evaluated but its
result is never used, so this breaks plans for a value nobody consumes. If a
Renovate bump gates the data source on `create_ai_agent_service` or switches it
to caller-supplied map keys, re-test the single-pass plan and retire this ADR.

No root-module change removes this. Building the identity resource IDs as
strings from `var.subscription_id`, the resource group name, and the identity
name would make the `for_each` keys static — but then the data source's `name`
and `resource_group_name` are static too, so Terraform reads it during plan and
fails on a missing identity instead. The module comes from the registry pinned
to an exact version ([ADR-0001](0001-adopt-azure-verified-modules.md)) and is
not forked.

## Decision

A new environment is applied in two passes:

```bash
make bootstrap ENV=dev     # terraform apply ... -var='enable_foundry=false'
make plan      ENV=dev
make apply     ENV=dev
```

Pass one creates the resource group, network, the seven user-assigned
identities, and every data service. Pass two adds the Foundry account,
project, and model deployments: the identity resource IDs are now known
strings in state, the `for_each` keys resolve, and the data source reads an
identity that exists.

The Foundry account is attached to the `foundry` identity only. The `cmk`
identity reaches the account through
`ai_foundry.customer_managed_key.user_assigned_identity_resource_id`, which the
module merges into the account identity block itself; listing it in
`managed_identities.user_assigned_resource_ids` as well would also grant a
key-unwrap-only identity the Cosmos and Storage data-plane roles that the
Standard Agent Setup hands to every account identity.

## Pass two also needs serial model deployments

`ai_model_deployments` is a `for_each` map, so Terraform creates every model
deployment in parallel — and Azure serialises operations on the parent
Cognitive Services account:

```
Error: Failed to create/update resource
  with module.ai_foundry[0].azapi_resource.ai_model_deployment["embeddings"],
RESPONSE 409: RequestConflict
  "Another operation is being performed on the parent resource
   '.../accounts/<foundry-account>'. Please try again later."
```

With two deployments (`gpt-4o` and `text-embedding-3-large`) one wins and the
other fails. The module's `azapi_resource.ai_model_deployment` has no `retry`
block, so nothing absorbs it — the upstream fix is
`retry { error_message_regex = ["RequestConflict"] }` on that resource, or
chaining the deployments.

Until then, pass two runs serially:

```bash
make apply ENV=dev ARGS="-parallelism=1"
```

Re-running a normal `make apply` also works, because the deployment that
succeeded is now in state and only one operation is left — but that is luck
scaling with the number of models, not a fix. Use `-parallelism=1` for a
green-field environment or any time more than one deployment is pending.

## Consequences

- This is a bootstrap cost, not an ongoing one. Once the identities are in
  state, every plan and apply is single-pass, including `terraform plan` in CI.
- A **green-field CI plan fails** until pass one has run against that
  environment. Promotion into a new staging or prod subscription needs the
  bootstrap apply first — it is not a `plan`-only step.
- `terraform destroy` followed by a fresh apply puts the environment back into
  the green-field case. Re-run pass one.
- If the identities are ever moved out of this root module into their own state
  (so the IDs arrive as data, known at plan time), this ADR can be dropped
  along with the `enable_foundry=false` pass.
- Reversing the identity attachment — putting `cmk` back into
  `user_assigned_resource_ids` — reintroduces surplus Cosmos and Storage
  data-plane role assignments for the CMK identity when
  `foundry_create_ai_agent_service` is true.

## Alternatives considered

- **`terraform apply -target=module.workload_identities` as pass one.** Fewer
  resources in the first pass and the same outcome. Rejected as the documented
  path because targeting prints a partial-state warning and hides the rest of
  the plan from review; `enable_foundry=false` is a flag the configuration
  already has and the diff is fully reviewable. Still a valid shortcut for an
  operator who wants the minimal first pass.
- **Give the Foundry account a system-assigned identity and attach no
  user-assigned identity.** The data source then iterates an empty set and the
  problem disappears permanently. Rejected: it contradicts
  [identity.md](../architecture/identity.md) — every service-to-service call in
  this stack runs on a user-assigned identity — and it would move the
  `foundry` identity's Storage, Search, and Cosmos role assignments onto a
  principal ID that only exists after the Foundry account is created, which
  makes those bindings a cycle with the data services the account connects to.
  Revisit if the pattern module gains a way to skip the lookup.
- **Fork the pattern module and key the data source on static map keys.**
  Correct fix, wrong repository. Blocked by ADR-0001 (registry sources, exact
  versions, no `git::`). The upstream shape to ask for is a
  `map(string)` input whose keys are set by the caller.
