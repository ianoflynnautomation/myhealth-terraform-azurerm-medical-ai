# terraform-azurerm-medical-ai-pipeline — operator entrypoints
#
# One root module, three environments. Everything is driven by ENV:
#
#   make plan ENV=dev          # or the shorthand: make plan-dev
#   make apply ENV=staging CONFIRM=staging
#
# Environments differ only by environments/<env>/{backend.hcl,terraform.tfvars}.
# Promotion is always dev -> staging -> prod.
#
# A NEW (or freshly destroyed) environment needs "make bootstrap" first: the
# Foundry pattern module cannot plan until the user-assigned identities exist,
# so pass 1 applies with enable_foundry=false. See docs/adr/0006. "make plan"
# on an empty state fails with "Invalid for_each argument" until it has run.
#
# Apply/destroy against staging or prod is gated behind CONFIRM=<env>; those
# environments are meant to go through workflow_dispatch with GitHub
# Environment reviewers, not a laptop (see AGENTS.md hard rules).

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

TF        ?= terraform
AZ        ?= az
KUBELOGIN ?= kubelogin
TFLINT    ?= tflint

ENV  ?= dev
ENVS := dev staging prod

ifeq ($(filter $(ENV),$(ENVS)),)
$(error ENV must be one of: $(ENVS) (got "$(ENV)"))
endif

ENV_DIR := environments/$(ENV)
BACKEND := $(ENV_DIR)/backend.hcl
TFVARS  := $(ENV_DIR)/terraform.tfvars
PLAN    := tfplan.$(ENV)

# Extra flags appended to terraform invocations, e.g. make plan ARGS="-target=..."
ARGS ?=

# Azure resource names are read out of the tfvars so there is a single source of
# truth (and no subscription/tenant IDs committed to this public repo).
tfvar = $(shell sed -nE 's/^[[:space:]]*$(1)[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p' $(TFVARS) 2>/dev/null | head -n1)

ENV_SHORT_dev     := dev
ENV_SHORT_staging := stg
ENV_SHORT_prod    := prod
ENV_SHORT          = $(ENV_SHORT_$(ENV))

RESOURCE_GROUP  ?= $(or $(call tfvar,resource_group_name),rg-bjjeire-$(ENV_SHORT)-sdc-01)
CLUSTER_NAME    ?= $(or $(call tfvar,aks_cluster_name),aks-bjjeire-$(ENV_SHORT)-sdc-01)
SUBSCRIPTION_ID ?= $(call tfvar,subscription_id)

# --- guards -----------------------------------------------------------------

define require_files
@for f in $(1); do \
  test -f "$$f" || { printf 'missing %s — copy %s/example.%s and fill it in\n' "$$f" "$(ENV_DIR)" "$${f##*.}" >&2; exit 1; }; \
done
endef

define require_confirm
@if [ "$(ENV)" != "dev" ] && [ "$(CONFIRM)" != "$(ENV)" ]; then \
  printf 'refusing to run "%s" against %s from a workstation.\n' "$@" "$(ENV)" >&2; \
  printf 'staging/prod go through workflow_dispatch (see AGENTS.md). To override: make %s ENV=%s CONFIRM=%s\n' "$@" "$(ENV)" "$(ENV)" >&2; \
  exit 1; \
fi
endef

# --- terraform --------------------------------------------------------------

.PHONY: init
init: ## terraform init for ENV (-reconfigure, so switching ENV is safe)
	$(call require_files,$(BACKEND))
	$(TF) init -backend-config=$(BACKEND) -reconfigure $(ARGS)

.PHONY: init-upgrade
init-upgrade: ## terraform init -upgrade (pick up new provider/module versions)
	$(call require_files,$(BACKEND))
	$(TF) init -backend-config=$(BACKEND) -reconfigure -upgrade $(ARGS)

.PHONY: bootstrap
bootstrap: ## FIRST apply of a new/destroyed env: everything except AI Foundry (ADR-0006)
	$(require_confirm)
	$(call require_files,$(TFVARS))
	@printf 'Pass 1 of 2 (ADR-0006): applying with enable_foundry=false so the\n'
	@printf 'user-assigned identities exist before the Foundry module is planned.\n'
	@printf 'Follow with: make plan ENV=%s && make apply ENV=%s\n\n' "$(ENV)" "$(ENV)"
	$(TF) apply -var-file=$(TFVARS) -var='enable_foundry=false' -auto-approve $(ARGS)

.PHONY: plan
plan: ## terraform plan -> tfplan.<ENV>
	$(call require_files,$(TFVARS))
	$(TF) plan -var-file=$(TFVARS) -out=$(PLAN) $(ARGS)

.PHONY: plan-destroy
plan-destroy: ## terraform plan -destroy -> tfplan.<ENV> (review before destroy)
	$(call require_files,$(TFVARS))
	$(TF) plan -destroy -var-file=$(TFVARS) -out=$(PLAN) $(ARGS)

.PHONY: show
show: ## terraform show tfplan.<ENV>
	@test -f $(PLAN) || { printf 'no %s — run "make plan ENV=%s" first\n' "$(PLAN)" "$(ENV)" >&2; exit 1; }
	$(TF) show $(PLAN) $(ARGS)

.PHONY: show-json
show-json: ## terraform show -json tfplan.<ENV> (for jq / set-diff analysis)
	@test -f $(PLAN) || { printf 'no %s — run "make plan ENV=%s" first\n' "$(PLAN)" "$(ENV)" >&2; exit 1; }
	@$(TF) show -json $(PLAN)

.PHONY: apply
apply: ## terraform apply tfplan.<ENV> (the saved plan)
	$(require_confirm)
	@test -f $(PLAN) || { printf 'no %s — run "make plan ENV=%s" first\n' "$(PLAN)" "$(ENV)" >&2; exit 1; }
	$(TF) apply $(PLAN) $(ARGS)

.PHONY: apply-auto
apply-auto: ## terraform apply -auto-approve (no saved plan)
	$(require_confirm)
	$(call require_files,$(TFVARS))
	$(TF) apply -var-file=$(TFVARS) -auto-approve $(ARGS)

.PHONY: destroy
destroy: ## terraform destroy -auto-approve, then purge soft-deleted remnants
	$(require_confirm)
	$(call require_files,$(TFVARS))
	$(TF) destroy -var-file=$(TFVARS) -auto-approve $(ARGS)
	@$(MAKE) --no-print-directory purge ENV=$(ENV) CONFIRM=$(CONFIRM)

# Cognitive Services accounts soft-delete on destroy and keep their name and
# custom subdomain reserved, so the next apply fails with
# 409 FlagMustBeSetForRestore. The azurerm provider's purge-on-destroy feature
# cannot help (the AVM module uses azapi, which ignores provider features), so
# the purge is explicit. Key Vault is handled by the provider instead, and is
# not purgeable at all while purge protection is on.
# See docs/known-upstream-issues.md.
.PHONY: purge
purge: ## purge soft-deleted remnants for ENV (irreversible; run after destroy)
	$(require_confirm)
	@printf 'Purging soft-deleted remnants for ENV=%s. This is irreversible.\n' "$(ENV)"
	@l="$(call tfvar,location)"; \
	for n in "$(call tfvar,document_intelligence_name)" "$(call tfvar,foundry_name)"; do \
	  test -n "$$n" || continue; \
	  if $(AZ) cognitiveservices account purge --name "$$n" --resource-group "$(RESOURCE_GROUP)" --location "$$l" -o none 2>/dev/null; then \
	    printf '  purged cognitive account %s\n' "$$n"; \
	  else \
	    printf '  nothing to purge for cognitive account %s\n' "$$n"; \
	  fi; \
	done
	@n="$(call tfvar,kv_name)"; l="$(call tfvar,location)"; \
	if [ -n "$$n" ]; then \
	  if $(AZ) keyvault purge --name "$$n" --location "$$l" -o none 2>/dev/null; then \
	    printf '  purged key vault %s\n' "$$n"; \
	  else \
	    printf '  key vault %s not purged (purge protection on, or not soft-deleted)\n' "$$n"; \
	  fi; \
	fi

.PHONY: refresh
refresh: ## terraform apply -refresh-only (reconcile state with reality)
	$(require_confirm)
	$(call require_files,$(TFVARS))
	$(TF) apply -refresh-only -var-file=$(TFVARS) $(ARGS)

.PHONY: force-unlock
force-unlock: ## release a stuck state lock: make force-unlock ENV=dev LOCK_ID=<id>
	$(require_confirm)
	@if [ -z "$(LOCK_ID)" ]; then \
		printf 'LOCK_ID is required: make %s ENV=%s LOCK_ID=<id>\n' "$@" "$(ENV)" >&2; \
		printf 'The ID is in the "Error acquiring the state lock" output ("ID: ..."), or in the\n' >&2; \
		printf 'lease metadata on the %s blob in the tfstate container.\n' "$(ENV).tfstate" >&2; \
		exit 1; \
	fi
	@printf 'Only force-unlock when you are certain no other plan/apply (CI included) is running.\n'
	$(TF) force-unlock $(if $(FORCE),-force,) $(LOCK_ID)

.PHONY: output
output: ## terraform output for ENV
	$(TF) output $(ARGS)

# --- azure / kubernetes -----------------------------------------------------

.PHONY: login
login: ## az login (and select the subscription from the ENV tfvars)
	$(AZ) login
	@if [ -n "$(SUBSCRIPTION_ID)" ]; then $(AZ) account set --subscription $(SUBSCRIPTION_ID); fi
	@$(AZ) account show --query '{name:name, id:id, tenant:tenantId}' -o yaml

.PHONY: kubeconfig
kubeconfig: ## az aks get-credentials + kubelogin convert-kubeconfig for ENV
	$(AZ) aks get-credentials \
		--resource-group $(RESOURCE_GROUP) \
		--name $(CLUSTER_NAME) \
		--overwrite-existing
	$(KUBELOGIN) convert-kubeconfig -l azurecli

.PHONY: kube-context
kube-context: ## show the current kube context and nodes
	@kubectl config current-context
	@kubectl get nodes -o wide

# --- quality ----------------------------------------------------------------

.PHONY: fmt
fmt: ## terraform fmt -recursive
	$(TF) fmt -recursive

.PHONY: fmt-check
fmt-check: ## terraform fmt -check (CI-equivalent)
	$(TF) fmt -recursive -check -diff

.PHONY: validate
validate: ## terraform validate
	$(TF) validate

.PHONY: test
test: ## terraform test (plan-only, mocked providers)
	$(TF) test $(ARGS)

.PHONY: lint
lint: ## tflint with the repo config
	$(TFLINT) --config="$(CURDIR)/.tflint.hcl"

.PHONY: pre-commit
pre-commit: ## pre-commit run --all-files (includes terraform-docs)
	pre-commit run --all-files

.PHONY: check
check: fmt-check validate lint test ## everything CI checks, locally

# --- housekeeping -----------------------------------------------------------

.PHONY: clean
clean: ## remove local plan files
	rm -f tfplan tfplan.* *.tfplan

.PHONY: clean-all
clean-all: clean ## also remove .terraform/ (requires a fresh init)
	rm -rf .terraform

.PHONY: env
env: ## print the resolved settings for ENV
	@printf '%-16s %s\n' ENV "$(ENV)" BACKEND "$(BACKEND)" TFVARS "$(TFVARS)" \
		PLAN "$(PLAN)" RESOURCE_GROUP "$(RESOURCE_GROUP)" CLUSTER_NAME "$(CLUSTER_NAME)"

# --- per-environment shorthands: <target>-<env> ------------------------------

ENV_TARGETS := init init-upgrade bootstrap plan plan-destroy show show-json apply apply-auto \
               destroy purge refresh force-unlock output login kubeconfig test env

define env_alias
.PHONY: $(1)-$(2)
$(1)-$(2):
	@$$(MAKE) --no-print-directory $(1) ENV=$(2)
endef
$(foreach e,$(ENVS),$(foreach t,$(ENV_TARGETS),$(eval $(call env_alias,$(t),$(e)))))

.PHONY: help
help: ## this list
	@printf 'medical-ai-pipeline terraform — ENV=%s (one of: %s)\n\n' "$(ENV)" "$(ENVS)"
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@printf '\nShorthands: %s\n' "$$(printf '<target>-{%s}' "$$(echo $(ENVS) | tr ' ' ',')")"
	@printf 'Guarded:    apply, apply-auto, destroy, refresh, force-unlock need CONFIRM=<env> when ENV != dev\n'
