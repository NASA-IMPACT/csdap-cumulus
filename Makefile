MODULE_DIRS = $(patsubst app/stacks/%,%,$(wildcard app/stacks/*))
IMAGE = csdap-cumulus
WORKDIR = /work
DOCKER_BUILD = docker build -t $(IMAGE) .
DOCKER_RUN = docker run \
  --interactive \
  --rm \
	--env-file .env \
	--volume ${PWD}:$(WORKDIR) \
	--volume ${HOME}/.aws:/root/.aws \
	--volume ${HOME}/.ssh:/root/.ssh
TERRASPACE = $(DOCKER_RUN) $(IMAGE) terraspace

.DEFAULT_GOAL := help
.PHONY: \
  all-up-yes \
	bash \
	build \
	clean-all \
	clean-cache \
	clean-logs \
	docker \
	help \
	logs \
	logs-follow \
	output

help: Makefile
	@echo
	@echo "Usage: make [options] target ..."
	@echo
	@echo "Options:"
	@echo
	@echo "  Run 'make -h' to list options."
	@echo
	@echo "Targets:"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo
	@echo "Where STACK is one of: $(MODULE_DIRS)"
	@echo

## all-up-yes: Deploys all modules (in dependency order) with automatic approval
all-up-yes:
	$(TERRASPACE) all up --yes

## all-SUBCOMMAND: Runs Terraspace SUBCOMMAND across all stacks (make all-help for list of SUBCOMMANDs)
all-%:
	$(TERRASPACE) all $(patsubst all-%,%,$@)

## bash: Runs bash terminal in Docker container
bash:
	$(DOCKER_RUN) --tty $(IMAGE)

## build: Runs Terraspace to build all stacks
build:
	$(TERRASPACE) build

## build-STACK: Runs Terraspace to build specified STACK
build-%:
	$(TERRASPACE) build $(patsubst build-%,%,$@)

## clean-all: Removes all Terraspace cache and log files
clean-all:
	$(TERRASPACE) clean all

## clean-cache: Removes all Terraspace cache files
clean-cache:
	$(TERRASPACE) clean cache

## clean-logs: Removes all Terraspace log files
clean-logs:
	$(TERRASPACE) clean logs

## docker: Builds Docker image for running Terraspace/Terraform
docker: Dockerfile .dockerignore .terraform-version Gemfile Gemfile.lock
	$(DOCKER_BUILD)

## logs: Shows last 10 lines of all Terraspace logs
logs:
	$(TERRASPACE) logs

## logs-follow: Tails all Terraspace logs
logs-follow:
	$(TERRASPACE) logs -f

## plan-STACK: Shows Terraform plan for specified STACK
plan-%:
	$(TERRASPACE) plan $(patsubst plan-%,%,$@)

## unlock-STACK_ID: Unlocks the Terraform state for the specified STACK using the specified lock ID
unlock-%:
	stack_id=$(patsubst unlock-%,%,$@); \
	stack=$${stack_id%%_*} id=$${stack_id##*_}; \
	$(TERRASPACE) force_unlock $${stack} $${id}

## up-STACK-yes: Deploys specified STACK with automatic approval
up-%-yes:
	$(TERRASPACE) up $(patsubst up-%-yes,%,$@) --yes

## up-STACK: Deploys specified STACK, prompting for approval
up-%:
	$(TERRASPACE) up $(patsubst up-%,%,$@)
