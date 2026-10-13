# ADR-0003: Private data plane by default; no public PaaS endpoints

- **Status:** Accepted
- **Date:** 2026-09-20
- **Applies to:** Key Vault, Storage, Document Intelligence, AI Search, SQL, Cosmos, AI Foundry

## Context

This stack handles extracted medical records (PHI). HIPAA and Azure healthcare
guidance expect encryption in transit (TLS 1.2+), encryption at rest with a
customer-managed key, and network isolation so data-plane endpoints are not on
the public internet.

GitHub-hosted runners and laptops sit outside the VNet. A fully private Key
Vault data plane means `azurerm_key_vault_secret` (and the AVM `secrets_value`
input) cannot be applied from those locations.

## Decision

Every PaaS resource is created with `public_network_access_enabled = false`
and a private endpoint in `PrivateEndpointSubnet`, linked to a
`privatelink.*` DNS zone. TLS minimum is 1.2. Shared access keys and Cognitive
/ Search local (API-key) authentication are disabled. Customer-managed keys
are attached when `kv_cmk_enabled` is true (the default).

The flags stay overridable (`kv_public_network_access_enabled`,
`storage_public_network_access_enabled`, …) so a laptop bootstrap can
temporarily open the Key Vault data plane, apply, and revert. That flip is an
operator action documented in [setup.md](../runbooks/setup.md), not a
permanent exception.

Apply of this stack after bootstrap is expected to run from a runner that can
resolve the private endpoints (self-hosted in `AppSubnet`, or a hub
jump/VPN). Management-plane ARM calls work from anywhere; data-plane secret
and blob operations do not.

## Consequences

- PHI never traverses a public PaaS endpoint in the default configuration.
- First apply of Key Vault secrets from a public runner will fail with a
  network/403 error. Use a VNet-integrated runner, or briefly set
  `kv_public_network_access_enabled = true` with an IP allowlist.
- Reversing this without reading the runbook looks like "just enable public
  access to unblock CI" and puts PHI on the public internet.

## Alternatives considered

- **Public Key Vault, private everything else** (the AKS platform pattern in
  ADR-0002 of bjjeire-terraform-azurerm-aks). Rejected here: there is no
  in-cluster External Secrets controller that must reach the vault from a
  public AKS API, and PHI raises the bar.
- **Public IP allowlists instead of private endpoints.** Weaker isolation;
  still a public endpoint. Available as an override, not the default.
