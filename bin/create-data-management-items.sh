#!/usr/bin/env bash

set -eou pipefail

function find_provider_bucket() {
  echo "var.buckets" |
    terraspace console cumulus 2>/dev/null |
    grep -B1 '"type" = "provider"' |
    grep '"name" = ' |
    sed -E 's/.+ = "(.+)"/\1/'
}

function sync_items() {
  local _path=${1}
  local _type=${2}
  local _file

  find "${_path}/${_type}" -name '*.json' -print0 | while IFS= read -r -d '' _file; do
    echo -n "Upserting ${_type} $(basename "${_file}")..."
    cumulus "${_type}" upsert --data "${_file}" >/dev/null
    echo "done"
  done
}

function sync_providers() {
  local _resources_path=${1}
  local _provider_bucket
  local _tmpdir

  echo -n "Determining provider bucket..."
  _provider_bucket=$(find_provider_bucket)
  echo "${_provider_bucket}"
  _tmpdir=$(mktemp --directory)
  # shellcheck disable=SC2064
  trap "rm -rf \"${_tmpdir}\"" EXIT

  mkdir -p "${_tmpdir}/${_resources_path}/providers"

  if [[ ${TS_ENV} =~ ^(sit|uat|ops|prod)$ ]]; then
    sync_items "${_resources_path}" "providers"
  else
    # We're dealing with a dev/sandbox environment, so we must set all provider
    # hosts to the sole provider bucket.
    find "${_resources_path}/providers" -type f -name '*.json' -print0 |
      xargs -0 -I{} sh -c 'jq .host=\"${1}\" "${2}" >"${3}"' -- "${_provider_bucket}" {} "${_tmpdir}/{}"

    sync_items "${_tmpdir}/${_resources_path}" "providers"
  fi
}

function main() {
  local _resources_path=app/stacks/cumulus/resources

  sync_providers "${_resources_path}"
  sync_items "${_resources_path}" "collections"
  sync_items "${_resources_path}" "rules"
}

main
