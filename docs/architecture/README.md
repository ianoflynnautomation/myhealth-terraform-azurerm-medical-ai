# Architecture

How the medical extraction and AI pipeline is put together. Start with
[context](context.md) if you are new, or [identity](identity.md) if something
is failing to authenticate.

| Page | Covers |
|---|---|
| [context.md](context.md) | Repository boundary, system diagram, request path, which documents belong here |
| [network.md](network.md) | VNet, subnets, NAT Gateway egress, private DNS, private endpoints |
| [identity.md](identity.md) | User-assigned identities and the RBAC matrix |
| [secrets.md](secrets.md) | Key Vault, CMK, keyless data-plane auth |
| [environments.md](environments.md) | dev / staging / prod matrix, state layout, promotion |

Decisions live in [../adr/](../adr/). Operator procedures live in
[../runbooks/](../runbooks/).
