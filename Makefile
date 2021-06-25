MODULES = cumulus data-persistence rds-cluster

.PHONY: help all $(MODULES)

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

## all: Make all out-of-date Terraform modules
up: $(MODULES)

## clean: Reset deployment timestamps
clean:
	rm *-tf/deploy

$(MODULES):
	$(MAKE) -C "${@}-tf"

## cumulus: Make the cumulus Terraform module (and dependencies)
cumulus: data-persistence

## data-persistence: Make the data-persistence Terraform module (and dependencies)
data-persistence: rds-cluster

## rds-cluster: Make the rds-cluster Terraform module (and dependencies)
