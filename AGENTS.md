# Agent guide — terraform-azurerm-medical-ai-pipeline

Terraform for an end-to-end medical data extraction and AI pipeline: one root
module, three environments (`dev` / `staging` / `prod`), applied against Azure.
Document Intelligence extracts structured JSON from clinical PDFs; Azure AI
Foundry, AI Search, and a SQL and/or Cosmos store power RAG over those records.

**Treat this repository as public.** Never commit a value you would not publish.
PHI never belongs in tfvars, state comments, or docs.

## Read this before you change anything

| If you are touching… | Read first |
|---|---|
| Any `variable` block | [ADR-0002](docs/adr/0002-flat-variables-over-object-inputs.md) |
| Module sources or versions | [ADR-0001](docs/adr/0001-adopt-azure-verified-modules.md) |
| Public network access / private endpoints | [ADR-0003](docs/adr/0003-private-data-plane-by-default.md) |
| AI Foundry dependents (KV, Search, Storage, Cosmos) | [ADR-0004](docs/adr/0004-byor-foundry-dependents.md) |
| SQL vs Cosmos storage tier flags | [ADR-0005](docs/adr/0005-storage-tier-sql-and-cosmos-flags.md) |
| First apply of a new environment | [ADR-0006](docs/adr/0006-two-phase-first-apply-for-foundry-identities.md) |
| Per-service region overrides | [ADR-0007](docs/adr/0007-search-may-run-outside-the-primary-region.md) |
| A plan/apply error from a module | [docs/known-upstream-issues.md](docs/known-upstream-issues.md) |
| Identities, RBAC | [docs/architecture/identity.md](docs/architecture/identity.md), [ADR-0008](docs/adr/0008-ai-search-runs-on-its-system-assigned-identity.md) |

The full index is [docs/adr/README.md](docs/adr/README.md). Several settings
look like security findings and are deliberate; the ADR is where the reasoning
lives. If you think an ADR is wrong, say so — don't silently reverse it.

## Conventions

**Variables are flat.** Every knob is its own top-level `variable` with a
default, so any of them can be overridden from a tfvars file. Never collapse
`var.foo_bar` and `var.foo_baz` into a single object variable, and never
hardcode a per-environment value in HCL. Type everything precisely — no `any`.
Add `description` and, where a wrong value would fail at apply time, a
`validation` block.

**Files are kebab-case, HCL is snake_case.** The root module is split by
concern: `main.<concern>.tf` and `variables.<concern>.tf`. Root files carry no
project prefix.

**Modules:** singular names (`modules/workload-identities/`) are generic
primitives. Each module has `main.tf`, `variables.tf`, `outputs.tf`,
`terraform.tf`, and a generated `README.md`.

**External modules** use registry `source` + an exact `version` (not a range).
Renovate raises the bumps. Do not introduce `git::` sources.

**Environments** differ only by `environments/<env>/terraform.tfvars` and
`backend.hcl`. There is no per-environment HCL and no workspace usage.
Promotion is always **dev → staging → prod**.

## Commands

```bash
terraform init -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform fmt -recursive
terraform validate
terraform test
tflint --config="$(pwd)/.tflint.hcl"
pre-commit run --all-files          # includes terraform-docs
terraform-docs markdown table --output-file README.md --output-mode inject modules/<name>
```

`plan` needs `TF_VAR_*` values in the environment; see
[docs/runbooks/setup.md](docs/runbooks/setup.md). Never run `apply` against
staging or prod from a laptop — those go through `workflow_dispatch` with
GitHub Environment reviewers.

## Hard rules

- **Never `git commit` or `git push`.** Leave changes in the working tree; the
  maintainer commits.
- **Never apply to prod.** Dev only, and only when asked.
- **Never commit secrets.** Connection strings, tenant IDs, and generated
  passwords do not belong in this repository. Plans, state files, and `*.pem`
  are gitignored — keep them that way.
- **Never commit tenant, subscription, or client IDs** in scratch notes or docs.
- **Regenerate module docs** after changing a module's variables or outputs, or
  CI fails.

## Where things live

```
main.*.tf              root composition, one concern per file
variables.*.tf         flat variables
modules/               local modules (UAMI composition)
environments/<env>/    backend.hcl + terraform.tfvars
docs/adr/              decisions and their rationale
docs/architecture/     how the platform is put together
docs/runbooks/         one-time and recurring operator procedures
tests/                 native terraform test (plan-only, mocked providers)
.github/workflows/     quality, unit test, renovate
```
