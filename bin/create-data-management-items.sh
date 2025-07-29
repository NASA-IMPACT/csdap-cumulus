#!/usr/bin/env bash

set -eou pipefail

function find_provider_bucket() {
  echo "var.buckets" |
    terraspace console cumulus 2>/dev/null |
    grep -B1 '"type" = "provider"' |
    grep '"name" = ' |
    sed -E 's/.+ = "(.+)"/\1/'
}

function fetch_cnm_params() {
  aws ssm get-parameter --with-decryption \
    --name "${1}" \
    --query "Parameter.Value"
}

function find_throttle_queue_url() {
  # Piping to sed shouldn't be necessary, but additional output may be
  # captured if console lock requests take >400ms.
  # See: https://github.com/hashicorp/terraform/issues/19176
  #
  # The final sed command should send the first line containing 'sqs' to stdout

  echo "aws_sqs_queue.background_job_queue.id" |
    terraspace console cumulus 2>/dev/null |
    sed '/sqs/!d;q'
}

function sync_items() {
  local _path=${1}
  local _type=${2}
  local _file

  find "${_path}/${_type}" -name '*.json' -print0 | while IFS= read -r -d '' _file; do
    if [[ ${_file} =~ 'CNM' ]]; then
      echo -n "Patching ${_type} $(basename "${_file}")..."
      # cumulus "${_type}" patch --data "${_file}" >/dev/null
    else
      echo -n "Upserting ${_type} $(basename "${_file}")..."
      cumulus "${_type}" upsert --data "${_file}" >/dev/null
    fi
    echo "done"
  done
}

function sync_providers() {
  local _resources_path=${1}
  local _provider_bucket
  local _tmpdir

  if [[ ${TS_ENV} =~ ^(sit|uat|ops|prod)$ ]]; then
    sync_items "${_resources_path}" "providers"
  else
    echo -n "Determining provider bucket..."
    _provider_bucket=$(find_provider_bucket)
    echo "${_provider_bucket}"
    _tmpdir=$(mktemp --directory)
    # shellcheck disable=SC2064
    trap "rm -rf \"${_tmpdir}\"" EXIT

    mkdir -p "${_tmpdir}/${_resources_path}/providers"

    # We're dealing with a dev/sandbox environment, so we must set all provider
    # hosts to the sole provider bucket.
    # shellcheck disable=SC2016
    find "${_resources_path}/providers" -type f -name '*.json' -print0 |
      xargs -0 -I{} sh -c 'jq .host=\"${1}\" "${2}" >"${3}"' -- "${_provider_bucket}" {} "${_tmpdir}/{}"

    sync_items "${_tmpdir}/${_resources_path}" "providers"
  fi
}

function sync_rules() {
  local _resources_path=${1}
  local _subscribe_notification_topic
  local _publish_response_topic
  local _queue_url
  local _tmpdir

  echo "Retrieving ARNs for CNM rules..."
  _subscribe_notification_topic=$(fetch_cnm_params "/shared/cumulus/cnm-sns-submission-topic")
  _publish_response_topic=$(fetch_cnm_params "/shared/cumulus/cnm-sns-response-topic")
  _queue_url=$(find_throttle_queue_url)

  if [[ ${#_subscribe_notification_topic} -le 5 || ${#_publish_response_topic} -le 5 || -z $_queue_url ]]; then
    echo "Missing one or more ARNs for CNM rules"
    echo "Continuing without updating current values"

    sync_items "${_resources_path}" "rules"
  else
    _tmpdir=$(mktemp --directory)
    # shellcheck disable=SC2064
    trap "rm -rf \"${_tmpdir}\"" EXIT

    # Copy all rules to temp directory
    cp -r --parents "${_resources_path}/rules" "${_tmpdir}"

    # Populate CNM rules with ARN properties and retrieved values
    # shellcheck disable=SC2016
    find "${_resources_path}/rules" -type f -name '*CNM*.json' -print0 |
      xargs -0 -I{} sh -c 'jq ".rule.value=${1} | .meta.cnmResponseStream=${2} | .queueUrl=${3}" "${4}" >"${5}"' -- "${_subscribe_notification_topic}" "${_publish_response_topic}" "${_queue_url}" {} "${_tmpdir}/{}"

    sync_items "${_tmpdir}/${_resources_path}" "rules"
  fi
}

function main() {
  local _resources_path=app/stacks/cumulus/resources

  sync_providers "${_resources_path}"
  sync_items "${_resources_path}" "collections"
  sync_rules "${_resources_path}"
}

main
