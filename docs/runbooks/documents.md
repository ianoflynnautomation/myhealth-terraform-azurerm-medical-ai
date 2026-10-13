# Working with clinical reports

Two separate things: **what to do with the documents**, and **what the Azure
bill looks like** (see [environments.md](../architecture/environments.md)).

This stack stores and searches **reports** (PDFs and scans of text). It is
not a PACS for raw MRI image files.

Terraform only provisions Azure. It does not upload PDFs or run extraction.
PHI stays in Azure, never in this git repository.

## What belongs in the pipeline

Treat each file as a **clinical report**, not as the original imaging study.

| You have | Put it in this pipeline? | Why |
|---|---|---|
| Blood test PDF / photo of a lab printout | Yes | Tables and values extract well |
| Surgery / operative note PDF | Yes | Narrative text |
| MRI / CT **report** (radiologist overview) | Yes | That is the written findings |
| MRI / CT **DICOM images** (the actual scan) | No | Needs a medical imaging store, not Document Intelligence |
| GP letters, discharge summaries | Yes | Same path as surgery notes |

## 1. Collect and name files (on your machine)

Export from the hospital/GP portal, or scan paper. Keep them **out of git**.

Suggested names:

```text
2024-03-15_bloods_hba1c.pdf
2024-01-20_surgery_knee_opnote.pdf
2023-11-02_mri_lumbar_report.pdf
```

Use `YYYY-MM-DD_type_short-topic.pdf`. That date becomes the record date
after extraction.

## 2. Decide where structured data lives

The Terraform flags already model this. They differ by environment:

| Store | Flag | Good for | Cheap dev (`environments/dev/example.tfvars`) |
|---|---|---|---|
| Azure SQL | `enable_sql` | Bloods / numeric labs over time (HbA1c, creatinine) | **off** |
| Cosmos MongoDB | `enable_cosmos` | Narrative reports (surgery, MRI overview) | **off** |
| Blob + AI Search | always on | Originals, extracted JSON, RAG | **this is the whole store** |

Staging/prod examples turn SQL and Cosmos **on**. For a personal archive,
blob + Search is enough. Turning a flag from true to false **destroys** that
store — do not flip it in prod without a data-migration plan
([ADR-0005](../adr/0005-storage-tier-sql-and-cosmos-flags.md)).

## 3. Apply the platform (once)

See [setup.md](setup.md) for backend, tfvars, and first apply.

```bash
cd /path/to/terraform-azurerm-medical-ai-pipeline
cp environments/dev/example.hcl    environments/dev/backend.hcl
cp environments/dev/example.tfvars environments/dev/terraform.tfvars
# Edit subscription_id and globally unique names

az login
terraform init -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform apply tfplan
```

**Dev (cheap profile)** opens the data plane so a laptop can upload. Search
is the free SKU (no semantic ranker, no private endpoints).

**Staging/prod** keep `enable_private_endpoints = true`. Upload and extract
must run from a machine that can reach the VNet (VPN, bastion, or a runner
in `AppSubnet`). A laptop on the public internet cannot talk to storage or
Document Intelligence there.

## 4. Upload

Put originals in the `inbound-pdfs` container. Do not overwrite; keep one
blob per report.

```bash
az storage blob upload \
  --account-name "<storage_account_name>" \
  --container-name inbound-pdfs \
  --name "2024-03-15_bloods_hba1c.pdf" \
  --file "./2024-03-15_bloods_hba1c.pdf" \
  --auth-mode login
```

On cheap dev this works after `az login`. On staging/prod it only works
from inside the VNet.

## 5. Extract (Document Intelligence, then optionally GPT-4o)

Happy path:

1. The **pipeline** identity calls Document Intelligence on the PDF.
   - Labs: layout / prebuilt document (tables).
   - Surgery + MRI reports: Read + Layout, then Foundry **gpt-4o** to turn
     OCR text into JSON (`test_name`, `value`, `unit`, `date`, `findings`,
     `impression`, …).
2. Write JSON to the `extracted-json` container.
3. Upsert into SQL and/or Cosmos when those flags are on.

You still need a small worker (script, Function, or Container App) to make
those API calls. This repository does not run extraction.

Cheap-dev Document Intelligence is **F0** (about 500 pages/month). Staging
and prod use **S0** (pay per page).

## 6. Index for questions

AI Search indexes the JSON. After that you can ask Foundry things like:

- "What was my last HbA1c and the one before it?"
- "Summarise the lumbar MRI impression."
- "List surgeries and dates."

Semantic ranker is **off** on the Search free SKU (dev). It is **on** for
basic/standard Search (staging/prod), so similar wording still hits the
right report.

## 7. Keep using it

| New document | Action |
|---|---|
| New bloods | Upload → extract → SQL row(s) if enabled, always Search |
| New op note / MRI report | Upload → extract → Cosmos doc if enabled, always Search |
| Correction | Upload a new dated file; do not edit the old blob |

On cheap dev both SQL and Cosmos are off, so every document's durable copy
is the blob plus the Search index.
