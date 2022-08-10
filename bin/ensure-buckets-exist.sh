#!/usr/bin/env bash
#
# Ensures that all of the specified buckets exist, creating all missing buckets.
# Exits with 0 (success) when all buckets exist, or when all missing buckets are
# successfully created.  If any creation fails with a "BucketAlreadyExists"
# error, the failure is ignored and creation is considered successful.
#
# Requires appropriate AWS environment variables to be set (AWS_ACCESS_KEY_ID,
# AWS_SECRET_ACCESS_KEY, and AWS_REGION), and constrains the bucket locations to
# the specified region.
#
# Usage:
#
#     ensure-buckets-exist.sh
#

set -Eeu

function bucket_exists() {
  local _bucket=${1}
  local _response

  if _response=$(aws s3api head-bucket --bucket "${_bucket}" 2>&1); then
    return 0
  elif [[ ${_response} =~ 404 ]]; then
    return 1
  else # Assume any other error indicates existence of bucket
    return 0
  fi
}

function create_bucket() {
  local _bucket=${1}
  local _region=${2}

  aws s3api create-bucket --bucket "${_bucket}" \
    --region "${_region}" \
    --create-bucket-configuration LocationConstraint="${_region}" 2>&1
}

function main() {
  declare _buckets

  _buckets="$(
    echo "var.buckets" |
      terraspace console cumulus |
      grep '"name" = ' |
      sed -E 's/.*= "([^"]*)"/\1/'
  )"

  for _bucket in ${_buckets}; do
    if ! bucket_exists "${_bucket}"; then
      create_bucket "${_bucket}" "${AWS_REGION}"
    fi
  done
}

main
