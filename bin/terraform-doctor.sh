#!/usr/bin/env bash

#
# Wrapper script for Terraform Doctor, which is a convenient means of fixing
# "duplicate resource" errors that occur during execution of the `make all-up`
# command.
#
# NOTE: Running `make up-MODULE` to deploy a specific module will NOT write to
# the Terraspace logs, but `make all-up` does write to the logs, and thus is
# required, if you want to make use of Terraform Doctor, without having to do
# any manual work of wrangling error messages.
#
# Recommended usage (after running `make all-up` and getting "duplicate
# resource" errors):
#
#   terraform-doctor.sh MODULE | bash
#
# where MODULE is the name of the module for which errors were produced.
#
# For example, to fix "duplicate resource" errors that occurred during
# deployment of the `cumulus` module (as part of running `make all-up`), run
# the following:
#
#   terraform-doctor.sh cumulus | bash
#

set -eou pipefail

_module=${1:-}

if [[ -z "${_module}" ]]; then
  echo "Usage: ${0} [cumulus | data-persistence | rds-cluster]" 2>&1
  echo "" 2>&1
  echo "ERROR: No module specified." 2>&1
  exit 1
fi

echo "pushd \$(terraspace info ${_module} --path)"
YARN_SILENT=1 yarn terraform-doctor <"log/up/${_module}.log"
echo "popd"
