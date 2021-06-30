#!/usr/bin/env bash

set -Eeou pipefail

# Renders new files from provided `*.example` files in each Cumulus module
# directory, automatically substituting environment variables defined in the
# `.env` file, such as `AWS_REGION` and `PREFIX`, to minimize errors due to
# manual edits to the files.
#
# This can be executed repeatedly, in case more modules (and corresponding
# `*.example` files) are added, but DOES NOT OVERWRITE files that have already
# been rendered.

_tf_example_files=$(find ./*-tf -maxdepth 1 -name \*.example)
# shellcheck disable=SC2016
_prefix="$(echo '${PREFIX}' | ./dotenv envsubst)"

for _tf_example_file in ${_tf_example_files}; do
  _tf_file=$(dirname "${_tf_example_file}")/$(basename -s .example "${_tf_example_file}")

  if [[ ${_prefix} =~ 'uat' || ${_tf_file} == ./cumulus-tf/terraform.tfvars ]]; then
    echo "Skipping '${_tf_file}'"
  else
    echo "Generating '${_tf_file}'"
    ./dotenv envsubst <"${_tf_example_file}" >"${_tf_file}"
  fi
done
