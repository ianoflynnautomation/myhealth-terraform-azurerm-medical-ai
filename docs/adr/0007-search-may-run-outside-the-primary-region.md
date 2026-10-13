# ADR-0007: AI Search may run outside the primary region

- **Status:** Accepted
- **Date:** 2026-10-12
- **Applies to:** `var.search_location`, `main.ai-search.tf`, `environments/dev/terraform.tfvars`

## Context

Every resource in this stack takes `var.location`. On 2026-10-12 a dev apply
could not create the Search service at all:

```
Error: creating Search Service (...): performing CreateOrUpdate:
unexpected status 400 (400 Bad Request) with error:
InsufficientResourcesAvailable: The region 'swedencentral' is currently out of
the resources required to provision new services. Try creating the service in
another region.
```

This is regional capacity, not quota: the subscription held zero Search
services, so the one-free-service-per-subscription limit was not in play, and
`Microsoft.Search/locations/<region>/usages` reported `free=0/1`,
`basic=0/16` in every region checked — those limits are subscription defaults
and say nothing about whether a region will actually accept a create.

The first substitute region failed differently:

```
Error: creating Search Service (...): unexpected status 403 (403 Forbidden)
with error: RequestDisallowedByAzure: Resource '<search-service>' was
disallowed by Azure: The selected region is currently not accepting new
customers: https://aka.ms/locationineligible.
```

So there are two independent region gates — capacity and new-customer
eligibility — and neither is visible through any read-only API. The only
reliable probe is to attempt a create. A throwaway free-tier service, deleted
immediately, settled it: `swedencentral` still returned
`InsufficientResourcesAvailable`, `northeurope` succeeded.

The alternatives were to pay for a SKU that might have capacity, to move the
whole stack, or to let one service sit elsewhere.

## Decision

`var.search_location` overrides the region for the Search service only. It
defaults to `null`, which means "use `var.location`" — so staging and prod are
unchanged and single-region unless somebody deliberately sets it.

```hcl
location = coalesce(var.search_location, module.rg.location)
```

`environments/dev/terraform.tfvars` sets `search_location = "northeurope"`. The
resource group, and therefore the Search service's own resource ID, stays in
the primary region; only the service's data plane moves.

## Consequences

- **This is a data-residency change.** The search index holds text extracted
  from clinical documents, so with this set the index lives in a different
  country from the blobs and the database. Sweden to the Netherlands keeps it
  inside the EU, which is why it is acceptable for dev on synthetic data. It
  is **not** automatically acceptable for staging or prod: that is a decision
  for whoever owns the data-processing agreement, not a capacity workaround.
- Storage, SQL, and Cosmos indexers become cross-region: egress is billed and
  indexer latency rises.
- With `enable_private_endpoints = true` the private endpoint is created in
  the primary-region VNet pointing at an out-of-region service. Azure supports
  cross-region private endpoints, but the traffic crosses the Microsoft
  backbone between regions, so leaving `search_location = null` in staging and
  prod is the default for a reason.
- Changing `search_location` on an existing environment **destroys and
  recreates** the Search service: indexes, indexers, skillsets, and synonym
  maps are lost and must be rebuilt by the application repo.
- A reviewer who sees one service in a different region from the other
  thirty will read it as a mistake. This ADR is the answer.
- **A Search service name cannot be reused immediately after a destroy.** The
  name lives in the Search control plane's own global namespace, which tears
  down asynchronously and is invisible to every read-only API — `az search
  service show` returns `ResourceNotFound`, `checkNameAvailability` returns
  `nameAvailable: true`, and the create still fails:

  ```
  Error: creating Search Service (...): unexpected status 409 (409 Conflict)
  with error: ServiceDeleting: Cannot provision service named
  '<search-service>' because a background operation is still in progress,
  please try again with exponential backoff or with a different service name
  ```

  So a destroy/redeploy cycle has to either wait out the teardown or bump
  `search_name`. `azurerm_search_service` has no retry block, so Terraform
  cannot absorb this for you — re-running `make bootstrap` is the retry.
  This is the one resource in the stack that does not support an immediate
  rebuild, and it is why `make purge` does not try to help here: there is
  nothing to purge, only something to wait for.

## Alternatives considered

- **Retry in the primary region.** Free of charge and the first thing to try;
  capacity errors often clear by themselves. Rejected here only because it did
  not clear — `swedencentral` was still refusing free-tier creates hours later.
- **`serverless`.** `Microsoft.Search/locations/*/usages` lists a `serverless`
  SKU, but neither this root module nor `Azure/avm-res-search-searchservice`
  0.3.0 accepts it. Revisit on a Renovate bump if the cheap profile matters
  more than the in-region placement.
- **`search_sku = "basic"` in the primary region.** Roughly $75/month and no
  guarantee the region has basic capacity either. Keeps everything in one
  region, so this is the better fix for staging and prod — the cheap-dev
  profile ([ADR-0005](0005-storage-tier-sql-and-cosmos-flags.md)) is what makes
  it the wrong trade for dev.
- **Move the whole stack to a region with capacity.** One consistent region
  and no residency split, but it rebuilds every resource and the choice of
  `swedencentral` is deliberate (Foundry model availability and quota).
