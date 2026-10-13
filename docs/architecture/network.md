# Network

Two subnets in one VNet. No implicit outbound SNAT.

| Subnet | Purpose | Egress | Private-endpoint policies |
|---|---|---|---|
| `AppSubnet` | Future pipeline compute (Functions, Container Apps, self-hosted runners) | NAT Gateway | Enabled |
| `PrivateEndpointSubnet` | Private endpoints for every PaaS resource | none | Disabled |

`default_outbound_access_enabled = false` on both. The app subnet's only
egress is the NAT Gateway.

## Private DNS

Each PaaS hostname has a `privatelink.*` zone linked to the VNet:

| Zone | Service |
|---|---|
| `privatelink.vaultcore.azure.net` | Key Vault |
| `privatelink.blob.core.windows.net` | Storage |
| `privatelink.cognitiveservices.azure.com` | Document Intelligence, Foundry |
| `privatelink.openai.azure.com` | Foundry OpenAI-compatible endpoint |
| `privatelink.services.ai.azure.com` | Foundry AI Services |
| `privatelink.search.windows.net` | AI Search |
| `privatelink.database.windows.net` | Azure SQL |
| `privatelink.mongo.cosmos.azure.com` | Cosmos MongoDB |

Zones are always created, even when `enable_sql` or `enable_cosmos` is false,
so toggling a flag does not recreate DNS.

## Address space

Override per environment. The examples use:

| Environment | VNet | App | Private endpoints |
|---|---|---|---|
| dev | 10.50.0.0/16 | 10.50.0.0/20 | 10.50.16.0/24 |
| staging | 10.60.0.0/16 | 10.60.0.0/20 | 10.60.16.0/24 |
| prod | 10.70.0.0/16 | 10.70.0.0/20 | 10.70.16.0/24 |
