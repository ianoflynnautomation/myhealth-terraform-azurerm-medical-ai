# Secrets

There are almost none.

- Storage account keys: disabled (`shared_access_key_enabled = false`).
- Document Intelligence / Foundry / Search local API keys: disabled.
- SQL SQL-auth password: not created (`azuread_authentication_only = true`).
- Cosmos local auth: disabled.

Workloads authenticate with the user-assigned identities in
[identity.md](identity.md) and receive data-plane tokens from Entra.

## Key Vault

RBAC authorization (no access policies). The Terraform runner is Key Vault
Administrator so it can create the CMK. Workload identities are Secrets User
or Crypto Service Encryption User, never Administrator.

Purge protection is on. Soft-delete retention defaults to 90 days.

Public network access is **off** ([ADR-0003](../adr/0003-private-data-plane-by-default.md)).
Secret CRUD from a laptop will fail unless you are on the VNet or you
temporarily allow public access with an IP allowlist.

## Customer-managed keys

An RSA-4096 key named `cmk-medical-pipeline` (override `kv_cmk_key_name`) is
always created. When `kv_cmk_enabled` is true (the default) it is attached to:

- Storage
- Document Intelligence
- AI Search (system-assigned identity; UAMI CMK is not yet supported by the
  Search AVM)
- Azure SQL TDE
- Cosmos DB
- AI Foundry

The `cmk` identity is granted `Key Vault Crypto Service Encryption User` and
attached to each of those accounts.

## What must never land in git

Tenant IDs, subscription IDs, client secrets, connection strings, PHI, and
plan files. `*.tfvars` is gitignored except `example.tfvars`.
