DOCKER_BUILD = docker build -t $(IMAGE) .
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
  --workdir $(WORKDIR)
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

## all-up-yes: Deploys all modules (in dependency order) with automatic approval
all-up-yes: install
	$(TERRASPACE) all up --yes

## all-graph: Draws module dependency graph in text format
all-graph:
	$(TERRASPACE) all graph --format text

all-up: install

## all-SUBCOMMAND: Runs Terraspace SUBCOMMAND across all stacks (make all-help for list of SUBCOMMANDs)
all-%:
	$(TERRASPACE) all $(patsubst all-%,%,$@)

## bash: Runs bash terminal in Docker container
bash: install
	$(DOCKER_RUN) --interactive $(IMAGE)

## bash-STACK: Runs bash terminal in Docker container at STACK's Terraspace cache dir
bash-%:
	$(DOCKER_RUN) --interactive --workdir /work/.terraspace-cache/$(AWS_REGION)/$(TS_ENV)/stacks/$* $(IMAGE)

## build: Runs Terraspace to build all stacks
build: install
	$(TERRASPACE) build

build-cumulus: install

## build-STACK: Runs `terraspace build` for specified STACK
build-%:
	$(TERRASPACE) build $*

## check-setup: Runs `terraspace check_setup`
check-setup:
	$(TERRASPACE) check_setup

## clean-all: Removes all Terraspace cache and log files
clean-all:
	$(TERRASPACE) clean all

## clean-cache: Removes all Terraspace cache files
clean-cache:
	$(TERRASPACE) clean cache

## clean-logs: Removes all Terraspace log files
clean-logs:
	$(TERRASPACE) clean logs

## create-test-data: Creates data for use with discovery/ingestion smoke test
create-test-data:
	$(DOCKER_RUN) $(IMAGE) -ic "bin/create-test-data.sh"

## docker: Builds Docker image for running Terraspace/Terraform
docker: Dockerfile .dockerignore .terraform-version Gemfile Gemfile.lock
	$(DOCKER_BUILD)

## init-STACK: Runs `terraform init` for specified STACK
init-%:
	$(TERRASPACE) init $*

install:
	$(DOCKER_RUN) $(IMAGE) -ic "YARN_SILENT=1 yarn install --ignore-optional && YARN_SILENT=1 yarn --cwd scripts install"

## logs: Shows last 10 lines of all Terraspace logs
logs:
	mkdir -p log/{init,plan,up}
	tail log/**/*.log

## logs-follow: Tails all Terraspace logs
logs-follow:
	mkdir -p log/{init,plan,up}
	$(TERRASPACE) list --type stack | tr -d '\r' | xargs -L1 basename | xargs -I{} touch log/{init,plan,up}/{}.log
	tail -f log/**/*.log

## nuke: DANGER! Completely annihilates your Cumulus stack (after confirmation)
nuke:
	$(DOCKER_RUN) $(IMAGE) -ic "bin/nuke.sh"

## output-STACK: Runs `terraform output` for specified STACK
output-%:
	$(TERRASPACE) output $*

plan-cumulus: install

## plan-STACK: Runs `terraform plan` for specified STACK
plan-%:
	$(TERRASPACE) plan $*

## pre-deploy-setup: Setup resources prior to initial deployment (idempotent)
pre-deploy-setup:
	# Tail terraspace logs in background so we can see output from subsequent
	# command to initialize all terraform modules.  After initialization is
	# complete, kill the background process that follows the logs.
	mkdir -p log/init
	$(TERRASPACE) list --type stack | tr -d '\r' | xargs -L1 basename | xargs -I{} touch log/init/{}.log
	tail -f log/init/*.log & $(TERRASPACE) all init; kill $$!
	$(DOCKER_RUN) $(IMAGE) -ic "bin/ensure-buckets-exist.sh"
	$(DOCKER_RUN) $(IMAGE) -ic "bin/copy-launchpad-pfx.sh"

## terraform-doctor-STACK: Fixes "duplicate resource" errors for specified STACK
terraform-doctor-%: install
	$(DOCKER_RUN) $(IMAGE) -ic "bin/terraform-doctor.sh $* | bash -v"

## test: Runs tests
test: install
	$(DOCKER_RUN) $(IMAGE) -ic "yarn test"

## unlock-STACK_ID: Unlocks Terraform state for specified STACK using specified lock ID
unlock-%:
	stack_id=$*; stack=$${stack_id%%_*} id=$${stack_id##*_}; \
	$(TERRASPACE) force_unlock $${stack} $${id}

up-cumulus-yes: install

## up-STACK-yes: Deploys specified STACK with automatic approval
up-%-yes:
	$(TERRASPACE) up $* --yes

up-cumulus: install

## up-STACK: Deploys specified STACK, prompting for approval
up-%:
	$(TERRASPACE) up $*

## validate-STACK: Runs `terraform validate` for specified STACK
validate-%:
	$(TERRASPACE) validate $*
