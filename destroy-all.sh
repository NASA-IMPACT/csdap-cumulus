#!/usr/bin/env bash

set -Eeuo pipefail

function usage() {
  echo
  echo "DANGER! THIS DESTROYS YOUR ENTIRE CUMULUS DEPLOYMENT, INCLUDING ALL DATA!"
  echo "However, you will be prompted for explicit approval."
  echo
  echo "Usage:"
  echo "  ${BASH_SOURCE[0]}"
  echo
}

function die() {
  local message=${1}

  echo
  echo ERROR: "${message}" >&2
  usage
  exit 1
}

function parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case ${1:-} in
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Invalid command argument: ${1}"
      ;;
    esac
  done

  return 0
}

function run() {
  echo "+ " "$@"
  eval "$@"
}

function destroy() {
  local _module_dir=${1}

  echo "pushd \"${_module_dir}\""
  echo "./tf init -reconfigure"
  echo "./tf destroy -auto-approve"
  echo "popd"
}

function delete_tables() {
  local _prefix
  local _tables

  _prefix=${1}
  _tables=$(
    ./dotenv aws dynamodb list-tables \
      --output json \
      --query "TableNames[?starts_with(@, 'cumulus-${_prefix}-') && ends_with(@, 'Table')]" \
      --output text
  )

  for _table in ${_tables}; do
    echo "./dotenv aws dynamodb delete-table --table-name \"${_table}\""
  done
}

function delete_rds_cluster() {
  local _prefix
  local _tables

  _prefix=${1}

  echo "./dotenv aws rds modify-db-cluster --db-cluster-identifier cumulus-${_prefix}-rds-serverless --no-deletion-protection"
  echo "./dotenv aws rds delete-db-cluster --db-cluster-identifier cumulus-${_prefix}-rds-serverless --skip-final-snapshot"
}

function delete_buckets() {
  local _prefix
  local _buckets

  _prefix=${1}
  _buckets=$(
    ./dotenv aws s3api list-buckets \
      --query "Buckets[?starts_with(Name, 'csdap-cumulus-${_prefix}-') && !contains(Name, '-tf')].Name" \
      --output text
  )

  for _bucket in ${_buckets}; do
    echo "./dotenv aws s3 rb --force \"s3://${_bucket}\""
  done
}

function list_dangling_resources() {
  local _prefix=${1}

  echo ""
  echo "Here are additional resources that you may wish to destroy manually."
  echo "In the case of secretsmanager resources, you can safely skip manual"
  echo "destruction, as they will eventually expire automatically."
  echo ""

  ./dotenv aws resourcegroupstaggingapi get-resources \
    --query "ResourceTagMappingList[].{arn:ResourceARN}" \
    --output text \
    --tag-filters "Key=Deployment,Values=cumulus-${_prefix}"
}

function make_plan() {
  destroy "cumulus-tf"
  delete_tables "${_prefix}"
  destroy "data-persistence-tf"
  delete_rds_cluster "${_prefix}"
  destroy "rds-cluster-tf"
  delete_buckets "${_prefix}"
}

function confirm_plan() {
  local _prefix
  local _plan
  local _reply

  _prefix=${1}
  shift
  _plan=("$@")

  echo "A plan of complete annihilation has been generated and is shown below."
  echo ""

  for _command in "${_plan[@]}"; do
    echo "  - ${_command}"
  done

  echo ""
  echo "DANGER! THIS DESTROYS YOUR ENTIRE CUMULUS DEPLOYMENT, INCLUDING ALL DATA!"
  echo "ARE YOU SURE YOU WANT TO COMPLETELY DESTROY THE '${_prefix}' DEPLOYMENT?"
  echo ""
  read -rp "Only 'yes' will be accepted for approval: " _reply
  echo ""

  if [[ $_reply =~ ^[yY][eE][sS]$ ]]; then
    return 0
  fi

  echo "Operation aborted."
  return 1
}

function execute_plan() {
  local _plan=("$@")
  local _command

  for _command in "${_plan[@]}"; do
    eval "${_command}"
  done
}

function main() {
  # shellcheck disable=SC2016
  local _prefix=${PREFIX:-$(echo '${PREFIX}' | ./dotenv envsubst)}
  local _plan=()

  parse_args "$@"

  echo "Making plans for complete annihilation..."
  echo ""
  mapfile -t _plan < <(make_plan "${_prefix}")

  if confirm_plan "${_prefix}" "${_plan[@]}"; then
    execute_plan "${_plan[@]}"
    list_dangling_resources "${_prefix}"
  fi
}

main "$@"
