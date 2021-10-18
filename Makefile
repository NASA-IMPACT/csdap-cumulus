DOCKER_BUILD = docker build -t $(IMAGE) .
DOCKER_RUN = docker run \
  --interactive \
  --rm \
	--env-file $(DOTENV) \
	--volume $(PWD):$(WORKDIR) \
	--volume $(HOME)/.aws:/root/.aws \
	--volume $(HOME)/.ssh:/root/.ssh
DOTENV = .env
IMAGE = csdap-cumulus
STACKS = $(patsubst app/stacks/%,%,$(wildcard app/stacks/*))
TERRASPACE = $(DOCKER_RUN) $(IMAGE) bundle exec terraspace
WORKDIR = /work

include $(DOTENV)

.DEFAULT_GOAL := help
.PHONY: \
  all-up-yes \
	all-% \
	bash \
	bash-% \
	build \
	check_setup \
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
	@echo "  Run 'make -h' to list options."
	@echo
	@echo "Targets:"
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo
	@echo "  where STACK is one of: $(STACKS)"
	@echo

## all-up-yes: Deploys all modules (in dependency order) with automatic approval
all-up-yes:
	$(TERRASPACE) all up --yes

## all-graph: Draws module dependency graph in text format
all-graph:
	$(TERRASPACE) all graph --format text

## all-SUBCOMMAND: Runs Terraspace SUBCOMMAND across all stacks (make all-help for list of SUBCOMMANDs)
all-%:
	$(TERRASPACE) all $(patsubst all-%,%,$@)

## bash: Runs bash terminal in Docker container
bash:
	$(DOCKER_RUN) --tty $(IMAGE)

## bash-STACK: Runs bash terminal in Docker container at STACK's Terraspace cache dir
bash-%:
	$(DOCKER_RUN) --tty --workdir /work/.terraspace-cache/$(AWS_REGION)/$(TS_ENV)/stacks/$* $(IMAGE)

## build: Runs Terraspace to build all stacks
build:
	$(TERRASPACE) build

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

## docker: Builds Docker image for running Terraspace/Terraform
docker: Dockerfile .dockerignore .terraform-version Gemfile Gemfile.lock
	$(DOCKER_BUILD)

## init-STACK: Runs `terraform init` for specified STACK
init-%:
	$(TERRASPACE) init $*

## logs: Shows last 10 lines of all Terraspace logs
logs:
	$(TERRASPACE) logs

## logs-follow: Tails all Terraspace logs
logs-follow:
	$(TERRASPACE) logs -f

## output-STACK: Runs `terraform output` for specified STACK
output-%:
	$(TERRASPACE) output $*

## plan-STACK: Runs `terraform plan` for specified STACK
plan-%:
	$(TERRASPACE) plan $*

## unlock-STACK_ID: Unlocks Terraform state for specified STACK using specified lock ID
unlock-%:
	stack_id=$*; stack=$${stack_id%%_*} id=$${stack_id##*_}; \
	$(TERRASPACE) force_unlock $${stack} $${id}

## up-STACK-yes: Deploys specified STACK with automatic approval
up-%-yes:
	$(TERRASPACE) up $* --yes

## up-STACK: Deploys specified STACK, prompting for approval
up-%:
	$(TERRASPACE) up $*

## validate-STACK: Runs `terraform validate` for specified STACK
validate-%:
	$(TERRASPACE) validate $*
