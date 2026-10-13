# Medical Data Extraction & AI Pipeline — Azure Terraform

[![terraform-test](https://img.shields.io/badge/terraform_test-native-844FBA?logo=terraform&logoColor=white)](.github/workflows/terraform-test.yml)
![Terraform](https://img.shields.io/badge/terraform-%E2%89%A5%201.14-844FBA?logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/azurerm-4.x-0078D4?logo=microsoftazure&logoColor=white)
[![Renovate](https://img.shields.io/badge/renovate-enabled-1A1F6C?logo=renovate)](renovate.json)

Production Terraform for an end-to-end **medical data extraction and AI
pipeline** on Azure. Document Intelligence turns clinical PDFs into JSON;
Azure SQL and/or Cosmos DB store the records; AI Search (semantic ranker)
indexes them; Azure AI Foundry hosts gpt-4o and embeddings for RAG.

Heavyweight Azure resources use official
[Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/),
pinned by registry `version`
([ADR-0001](docs/adr/0001-adopt-azure-verified-modules.md)).

## Documentation

| | |
|---|---|
| **[Architecture](docs/architecture/)** | [context](docs/architecture/context.md) · [network](docs/architecture/network.md) · [identity](docs/architecture/identity.md) · [secrets](docs/architecture/secrets.md) · [environments](docs/architecture/environments.md) |
| **[Decisions](docs/adr/)** | AVM, flat variables, private data plane, Foundry BYOR, SQL/Cosmos flags |
| **[Runbooks](docs/runbooks/)** | [One-time setup](docs/runbooks/setup.md) · [clinical reports](docs/runbooks/documents.md) |
| **[AGENTS.md](AGENTS.md)** | Conventions and hard rules |

## Repository structure

```
├── main.*.tf                  # Root composition, one concern per file
├── variables.*.tf             # Flat variables — every knob overridable from tfvars
├── outputs.tf
├── AGENTS.md
├── modules/
│   └── workload-identities/   # Composition wrapper over the AVM UAMI module
├── environments/
│   ├── dev/                   # backend.hcl + terraform.tfvars (+ example.tfvars)
│   ├── staging/
│   └── prod/
├── docs/
│   ├── adr/
│   ├── architecture/
│   └── runbooks/
└── .github/workflows/
```

## What gets provisioned

| Component | AVM module | Notes |
|---|---|---|
| Resource group | `avm-res-resources-resourcegroup` 0.4.0 | Tagged; PHI classification |
| VNet + NAT | `avm-res-network-virtualnetwork` 0.22.2, `natgateway` 0.3.2 | App subnet + private-endpoint subnet |
| Private DNS | `avm-res-network-privatednszone` 0.5.0 | One zone per PaaS hostname |
| Log Analytics | `avm-res-operationalinsights-workspace` 0.5.1 | Diagnostic destination |
| Key Vault | `avm-res-keyvault-vault` 0.11.0 | RBAC, CMK RSA-4096, private |
| Storage | `avm-res-storage-storageaccount` 0.10.0 | No keys, TLS 1.2, private |
| Document Intelligence | `avm-res-cognitiveservices-account` 0.11.1 | FormRecognizer, S0, custom subdomain |
| AI Search | `avm-res-search-searchservice` 0.3.0 | Semantic ranker, no API keys |
| Azure SQL | `avm-res-sql-server` 0.2.1 | Entra-only, TDE, audit (`enable_sql`) |
| Cosmos MongoDB | `avm-res-documentdb-databaseaccount` 0.11.0 | Autoscale (`enable_cosmos`) |
| AI Foundry | `avm-ptn-aiml-ai-foundry` 0.11.3 | BYOR connections to Search/Storage/KV/Cosmos |

## Prerequisites

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform) | ≥ 1.14 (CI pins 1.15.3) |
| [Azure CLI](https://learn.microsoft.com/cli/azure/) | 2.60+ |
| [tflint](https://github.com/terraform-linters/tflint) | 0.53+ |
| [terraform-docs](https://terraform-docs.io/) | 0.24.0 |

Azure roles for RBAC assignments and Cognitive / Search / SQL / Cosmos
registration are required. Full bootstrap is in
**[docs/runbooks/setup.md](docs/runbooks/setup.md)**.

## Deploying changes

Each environment is applied from the same root configuration — only the backend
and tfvars differ.

```bash
# Copy the examples (gitignored once renamed)
cp environments/dev/example.hcl    environments/dev/backend.hcl
cp environments/dev/example.tfvars environments/dev/terraform.tfvars
# Edit subscription_id and globally unique names in terraform.tfvars
# Dev example.tfvars is a cheap profile (no SQL/Cosmos/NAT/PEs, Search free, DI F0).

az login
terraform init -backend-config=environments/dev/backend.hcl

# A new environment is applied twice: Foundry needs the user-assigned
# identities to exist before it can plan (ADR-0006).
terraform apply -var-file=environments/dev/terraform.tfvars -var='enable_foundry=false'

terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform apply tfplan
```

Every apply after the first is single-pass. Full procedure:
[docs/runbooks/setup.md](docs/runbooks/setup.md).

**Promotion order is always dev → staging → prod.** Staging and prod apply
through `workflow_dispatch` with GitHub Environment reviewers, never from a
laptop.

Plans replay a few harmless diffs and the nested AVM modules emit deprecation
warnings; [docs/known-upstream-issues.md](docs/known-upstream-issues.md) lists
what is expected and what is not.

Quality gates:

```bash
terraform fmt -recursive
terraform validate
terraform test
tflint --config="$(pwd)/.tflint.hcl"
```

## Healthcare guardrails

- **Keyless.** User-assigned managed identities on every service. Storage
  keys, Cognitive/Search API keys, and SQL passwords are off.
- **Private.** `public_network_access_enabled = false` on KV, Storage,
  Document Intelligence, Search, SQL, Cosmos, and Foundry, with private
  endpoints and DNS ([ADR-0003](docs/adr/0003-private-data-plane-by-default.md)).
- **TLS 1.2+** on every resource that exposes the setting.
- **CMK.** RSA-4096 in Key Vault, attached when `kv_cmk_enabled` is true.
- **Audit.** Diagnostic settings to Log Analytics; SQL extended auditing and
  Defender-for-SQL alerts.

This configuration is designed to support a HIPAA-aligned architecture. It is
not a compliance certification. You still need a BAA with Microsoft, access
reviews, and application-level controls.

## Security

- **No standing credentials in git.** Workloads authenticate by managed
  identity — [identity.md](docs/architecture/identity.md).
- **Never commit PHI, tenant IDs, or plan files.**
