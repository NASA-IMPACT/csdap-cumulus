DOCKER_BUILD_OPTS ?= --quiet
DOCKER_BUILD = docker build $(DOCKER_BUILD_OPTS) -t $(IMAGE) .
DOCKER_RUN_OPTS ?=
DOCKER_RUN = docker run \
  --tty \
  --rm \
  --env-file $(DOTENV) \
  --env DOTENV=$(DOTENV) \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume csdap-cumulus.build:$(WORKDIR)/build \
  --volume csdap-cumulus.node_modules:$(WORKDIR)/node_modules \
  --volume csdap-cumulus.scripts.build:$(WORKDIR)/scripts/build \
  --volume csdap-cumulus.scripts.node_modules:$(WORKDIR)/scripts/node_modules \
  --volume csdap-cumulus.terraform-cache:$(WORKDIR)/.terraform \
  --volume csdap-cumulus.terraspace-cache:$(WORKDIR)/.terraspace-cache \
  --volume $(PWD):$(WORKDIR) \
  --volume $(HOME)/.aws:/root/.aws \
  --volume $(HOME)/.ssh:/root/.ssh \
  --workdir $(WORKDIR) \
  $(DOCKER_RUN_OPTS)
DOTENV ?= .env
IMAGE = csdap-cumulus
STACKS = $(patsubst app/stacks/%,\n  - %,$(wildcard app/stacks/*))
TERRASPACE = $(DOCKER_RUN) $(IMAGE) bundle exec terraspace
WORKDIR = /work

include $(DOTENV)

.DEFAULT_GOAL := help

$(VERBOSE).SILENT:

help: Makefile
	@echo
	@echo "Usage: make [options] target ..."
	@echo
	@echo "Options:"
	@echo "  Run 'make -h' to list options."
	@echo
	@echo "Targets:"
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo
	@echo "  where STACK is one of the following:\n$(STACKS)"
	@echo

## all-init: Initializes all modules (in dependency order)
all-init: logs-init install
	tail -f log/init/*.log & $(TERRASPACE) all init; kill $$!

## all-up: Deploys all modules (in dependency order), prompting for approval
all-up: logs-init install
	$(eval DOCKER_RUN_OPTS := --interactive)
	tail -f log/up/*.log & $(TERRASPACE) all up; kill $$!

## all-up-yes: Deploys all modules (in dependency order) with automatic approval
all-up-yes: logs-init install
	$(eval DOCKER_RUN_OPTS := --interactive)
	tail -f log/up/*.log & $(TERRASPACE) all up --yes; kill $$!

## all-SUBCOMMAND: Runs Terraspace SUBCOMMAND across all stacks (make all-help for list of SUBCOMMANDs)
all-%: install
	$(eval DOCKER_RUN_OPTS := --interactive)
	$(TERRASPACE) all $(patsubst all-%,%,$@)

## bash: Runs bash terminal in Docker container
bash: install
	$(DOCKER_RUN) --interactive $(IMAGE)

## bash-STACK: Runs bash terminal in Docker container at STACK's Terraspace cache dir
bash-%: install
	$(DOCKER_RUN) --interactive --workdir /work/.terraspace-cache/$(AWS_REGION)/$(TS_ENV)/stacks/$* $(IMAGE)

## build: Runs Terraspace to build all stacks
build: install
	$(TERRASPACE) build

## build-STACK: Runs `terraspace build` for specified STACK
build-%: install
	$(TERRASPACE) build $*

## check-setup: Runs `terraspace check_setup`
check-setup: docker
	$(TERRASPACE) check_setup

## clean-all: Removes all Terraspace cache and log files
clean-all: docker
	$(TERRASPACE) clean all

## clean-cache: Removes all Terraspace cache files
clean-cache: docker
	$(TERRASPACE) clean cache

## clean-logs: Removes all Terraspace log files
clean-logs: docker
	$(TERRASPACE) clean logs

## console-STACK: Runs `terraspace console` for the specified STACK
console-%: docker
	$(eval DOCKER_RUN_OPTS := --interactive)
	$(TERRASPACE) console $*

## create-data-management-items: Creates/updates providers, collections, and rules
create-data-management-items: docker
	$(DOCKER_RUN) $(IMAGE) -ic "bin/create-data-management-items.sh"

## create-test-data: Creates data for use with discovery/ingestion smoke test
create-test-data: docker
	$(DOCKER_RUN) $(IMAGE) -ic "bin/create-test-data.sh"

## docker: Builds Docker image for running Terraspace/Terraform
docker: Dockerfile .dockerignore .terraform-version Gemfile Gemfile.lock package.json yarn.lock
	$(DOCKER_BUILD)

## fmt: Runs `terraspace fmt` to format all Terraform files
fmt: docker
	$(DOCKER_RUN) $(IMAGE) bundle exec 'terraspace fmt 2>/dev/null'

## init-STACK: Runs `terraform init` for specified STACK
init-%: docker
	$(TERRASPACE) init $*

install: docker
	$(DOCKER_RUN) $(IMAGE) -ic "YARN_SILENT=1 yarn install --ignore-optional && YARN_SILENT=1 yarn --cwd scripts install"

## logs: Shows last 10 lines of all Terraspace logs
logs:
	mkdir -p log/{init,plan,up}
	tail log/**/*.log

## logs-follow: Tails all Terraspace logs
logs-follow: logs-init
	tail -f log/**/*.log

logs-init: docker
	# Make sure all log/init/*.log files exist so we can tail them.  Oddly,
	# terraspace appends a carriage return ('\r' or ^M) to each stack name, so we
	# have to delete the trailing carriage returns before further piping.
	rm -rf log
	mkdir -p log/{init,plan,up}
	$(TERRASPACE) list --type stack | tr -d '\r' | xargs -L1 basename | xargs -I{} touch log/{init,plan,up}/{}.log

## nuke: DANGER! Completely annihilates your Cumulus stack (after confirmation)
nuke: docker
	$(DOCKER_RUN) -i $(IMAGE) -ic "bin/nuke.sh"

## output-STACK: Runs `terraform output` for specified STACK
output-%: docker
	$(TERRASPACE) output $*

## plan-STACK: Runs `terraform plan` for specified STACK
plan-%: install
	$(eval DOCKER_RUN_OPTS := --interactive)
	$(TERRASPACE) plan $*

## pre-deploy-setup: Setup resources prior to initial deployment (idempotent)
pre-deploy-setup: all-init
	# Ensure buckets exist, grab the name of the "internal" bucket, and copy launchpad.pfx there.
	$(DOCKER_RUN) --interactive $(IMAGE) -ic "bin/ensure-buckets-exist.sh 2>/dev/null"

## terraform-doctor-STACK: Fixes "duplicate resource" errors for specified STACK
terraform-doctor-%: docker
	$(DOCKER_RUN) $(IMAGE) -ic "bin/terraform-doctor.sh $* | bash -v"

## test: Runs tests
test: install
	$(DOCKER_RUN) $(IMAGE) -ic "yarn test"

## unlock-STACK_ID: Unlocks Terraform state for specified STACK using specified lock ID
unlock-%: docker
	stack_id=$*; stack=$${stack_id%%_*} id=$${stack_id##*_}; \
	$(TERRASPACE) force_unlock $${stack} $${id}

## up-STACK-yes: Deploys specified STACK with automatic approval
up-%-yes: logs-init install
	$(eval DOCKER_RUN_OPTS := --interactive)
	$(TERRASPACE) up $* --yes | tee -a log/up/$*.log

## up-STACK: Deploys specified STACK, prompting for approval
up-%: logs-init install
	$(eval DOCKER_RUN_OPTS := --interactive)
	$(TERRASPACE) up $* | tee -a log/up/$*.log

## update-launchpad: Updates Launchpad certificate and passcode (expects LAUNCHPAD_PFX env var to be set to path to Launchpad certificate file [.pfx])
update-launchpad:
	$(DOCKER_RUN) --interactive $(IMAGE) -ic "bin/update-launchpad-pfx.sh ${LAUNCHPAD_PFX}"

## validate-STACK: Runs `terraform validate` for specified STACK
validate-%: docker
	$(TERRASPACE) validate $*

## Zip any lambda functions to prepare for deployment
zip_lambdas:
	DOTENV=$(DOTENV) \
	sh app/stacks/post-deploy-mods/resources/lambdas/pre-filter-DistributionApiEndpoints/zip_lambda.sh
