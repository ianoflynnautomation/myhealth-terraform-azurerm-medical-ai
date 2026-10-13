# Context

This repository provisions the Azure platform for an end-to-end medical data
extraction and AI pipeline. It does **not** deploy the worker that calls
Document Intelligence or the RAG application — those live in a separate
application repository and authenticate with the user-assigned identities
created here.

## What this stack provisions

```
Resource group
├── Virtual network
│   ├── AppSubnet          (compute; NAT Gateway egress)
│   └── PrivateEndpointSubnet
├── NAT Gateway
├── Private DNS zones      (vault, blob, cognitive, openai, ai, search, sql, cosmos mongo)
├── Log Analytics
├── Key Vault              (RBAC, CMK RSA-4096, private endpoint)
├── Storage account        (inbound-pdfs, extracted-json, search-staging)
├── Document Intelligence  (FormRecognizer, S0, custom subdomain)
├── AI Search              (semantic ranker, RBAC only)
├── Azure SQL              (optional; Entra-only, TDE, audit)
├── Cosmos DB MongoDB API  (optional; autoscale)
├── AI Foundry             (account + project + model deployments; BYOR connections)
└── User-assigned identities (pipeline, di, foundry, search, sql, cosmos, cmk)
```

## Request path (happy path)

1. A pipeline workload in `AppSubnet` (or a federated GitHub Action using the
   `pipeline` identity) uploads a clinical PDF to `inbound-pdfs`.
2. The same identity calls Document Intelligence over its private endpoint.
   Document Intelligence reads the PDF using its own identity
   (`Storage Blob Data Contributor`).
3. Extracted JSON is written to `extracted-json` and, depending on flags, to
   Azure SQL and/or Cosmos DB.
4. AI Search indexes the JSON (indexer uses the `search` identity). Semantic
   ranker is on.
5. Azure AI Foundry hosts gpt-4o and text-embedding-3-large. The Foundry
   project is pre-connected to Search, Storage, Key Vault, and Cosmos so RAG
   agents can retrieve without connection strings.

## What belongs in the pipeline

This stack stores and searches **reports** (PDFs and scans of text). It is
not a PACS. How to name, upload, and extract files is
[documents.md](../runbooks/documents.md).

| You have | In this pipeline? | Why |
|---|---|---|
| Blood test PDF / photo of a lab printout | Yes | Tables and values extract well |
| Surgery / operative note PDF | Yes | Narrative text |
| MRI / CT **report** (radiologist overview) | Yes | Written findings |
| MRI / CT **DICOM images** (the actual scan) | No | Needs a medical imaging store |
| GP letters, discharge summaries | Yes | Same path as surgery notes |

## What this stack does not own

- The extraction worker, chunking job, or chat UI.
- In-cluster GitOps, AKS, or Cloudflare.
- Entra app registrations for end-user login.
- Any document that contains PHI — PHI stays in Azure, never in this git
  repository.
- Raw imaging studies (DICOM).
