# ADR-0002: Root module inputs are flat variables, never grouped objects

- **Status:** Accepted
- **Date:** 2026-09-20
- **Applies to:** every `variables.*.tf` in the root module

## Context

Three environments share one root module. Everything that differs between them
lives in `environments/<env>/terraform.tfvars` — there is no per-environment
HCL, no `count` on environment name to select resource shapes, and no
workspaces.

That only holds if every setting is individually overridable. The moment a
group of related settings is collapsed into one object variable, overriding one
field in tfvars means restating the whole object, and defaults inside the
object stop applying.

## Decision

Each setting is its own top-level `variable` with a type, a description, and a
default that is safe for dev.

Rules:

- **No `any` types.** Every variable is precisely typed.
- **`description` on everything.** Enforced by `terraform_documented_variables`.
- **`validation` blocks where a wrong value fails late.** Prefer failing at
  plan time with a sentence explaining the fix over failing at apply time with
  an Azure API error.
- **Never branch on `var.environment` alone** to pick a resource shape. Use
  `coalesce(var.foo, <dev-safe default>)` so the variable stays overridable.

Grouped objects are acceptable *inside* a module boundary where the whole
object is the unit of configuration — `var.kv_network_acls`,
`var.storage_containers`, `var.foundry_model_deployments` — because AVM
modules take them that way and callers replace them wholesale.

## Consequences

- `variables.*.tf` is large, and adding a setting means writing a full variable
  block rather than adding a field to an object. That verbosity is the point.
- Any environment can override any knob without touching HCL.
- A new setting must ship with a default that preserves existing behaviour, or
  every committed tfvars breaks at once.

## Alternatives considered

- **One object per concern** (`var.sql = { ... }`). Fewer, tidier declarations;
  loses per-field defaulting and forces tfvars to restate whole blocks.
- **Workspaces.** Rejected: state separation is already handled by per-env
  backend keys.
