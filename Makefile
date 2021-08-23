MODULE_DIRS = $(wildcard *-tf)
CLEAN_TARGETS = $(addsuffix /clean,$(MODULE_DIRS))
DEPLOY_TARGETS = $(addsuffix /deploy,$(MODULE_DIRS))
FORMAT_TARGETS = $(addsuffix /format,$(MODULE_DIRS))
OUTPUT_TARGETS = $(addsuffix /output,$(MODULE_DIRS))
PLAN_TARGETS = $(addsuffix /plan,$(MODULE_DIRS))

ENV = bin/env.sh
IMAGE = csdap-cumulus
WORKDIR = /work
DOCKER_BUILD = docker build -t $(IMAGE) .
DOCKER_RUN = docker run \
  --rm \
	--volume ${PWD}:$(WORKDIR) \
	--volume ${HOME}/.aws:/root/.aws \
	--volume ${HOME}/.ssh:/root/.ssh
TERRAFORM = $(IMAGE) terraform

.PHONY: bash \
	clean \
	deploy \
	destroy \
	docker \
	format \
	help \
	output \
	$(CLEAN_TARGETS) \
	$(FORMAT_TARGETS) \
	$(OUTPUT_TARGETS)
.DEFAULT_GOAL := help

help: Makefile
	@echo
	@echo "Usage: make [options] target ..."
	@echo
	@echo "Run 'make -h' to list available options."
	@echo
	@echo "Available targets:"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo

.env: .env.example
	@echo
	@echo "The .env.example file has changed since you last updated your .env file."
	@echo "Update your .env file accordingly.  If there is no need to change your"
	@echo ".env file, then run 'touch .env' to update its timestamp."
	@echo
	@# Force a failure
	@grep "nothing" nosuchfile 2>/dev/null

# Regenerate terraform.tf and terraform.tfvars when .env has been updated or
# when the script that generates them changes.
%/terraform.tf: .env bin/env.sh bin/generate-%-configs.sh
	$(ENV) $(patsubst %/terraform.tf,bin/generate-%-configs.sh,$@)

## bash: Run bash terminal in Docker container
bash:
	$(DOCKER_RUN) -it $(IMAGE) bash

## clean: Clean up build/deployment artifacts for all Terraform modules
clean: $(CLEAN_TARGETS)

## deploy: Deploy all Terraform modules
deploy: $(DEPLOY_TARGETS)
cumulus-tf/deploy: data-persistence-tf/deploy
data-persistence-tf/deploy: rds-cluster-tf/deploy
rds-cluster-tf/deploy:

## destroy: DANGER! Destroy entire Cumulus deployment and data! (confirmation required)
destroy:
	$(ENV) bin/destroy.sh

## docker: Build Docker image for Cumulus deployment environment
docker: Dockerfile
	$(DOCKER_BUILD)

## format: Format all *.tf and *.tfvars in all Terraform module directories
format: $(FORMAT_TARGETS)

## output: Show all outputs for all Terraform modules
output: $(OUTPUT_TARGETS)

## plan: Show plans for all Terraform modules
plan: $(PLAN_TARGETS)

## MODULE_DIR/clean: Clean up build/deployment artifacts for the Terraform module in the directory MODULE_DIR
$(CLEAN_TARGETS):
	rm -f "$(patsubst %/clean,%,$@)/deploy"

## MODULE_DIR/deploy: Deploy the Terraform module (and dependencies) in the directory MODULE_DIR
%/deploy: %/*.tf %/*.tfvars
	$(ENV) bin/setup-tf-backend-resources.sh
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/deploy,%,$@) $(TERRAFORM) fmt -check -diff
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/deploy,%,$@) $(TERRAFORM) init -reconfigure
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/deploy,%,$@) $(TERRAFORM) apply -input=false -auto-approve
	touch $@

## MODULE_DIR/format: Format the *.tf and *.tfvars files in the directory MODULE_DIR
$(FORMAT_TARGETS):
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/format,%,$@) $(TERRAFORM) fmt -check -diff

## MODULE_DIR/output: Show the outputs for the Terraform module in the directory MODULE_DIR
$(OUTPUT_TARGETS):
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/output,%,$@) $(TERRAFORM) output

## MODULE_DIR/plan: Show plan for the Terraform module in the directory MODULE_DIR
%/plan: %/*.tf %/*.tfvars
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/plan,%,$@) $(TERRAFORM) init -reconfigure
	$(DOCKER_RUN) --workdir $(WORKDIR)/$(patsubst %/plan,%,$@) $(TERRAFORM) plan -input=false
