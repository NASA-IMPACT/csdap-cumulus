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
#     ensure-buckets-exist.sh [BUCKET [BUCKET [...]]]
#

set -Eeu

declare -a _required_buckets
declare -a _existing_buckets
declare -A _bucket_map

_required_buckets=("${@}")
mapfile -t _existing_buckets < <(aws s3api list-buckets --query Buckets[].Name --output text | tr '\t' '\n')

for _bucket in "${_existing_buckets[@]}"; do
  _bucket_map["${_bucket}"]=${_bucket}
done

for _bucket in "${_required_buckets[@]}"; do
  if [[ -n "${_bucket_map[${_bucket}]:-}" ]]; then
    echo "Found bucket '${_bucket}'"
  else
    echo "Creating bucket '${_bucket}'..."

    if ! _output=$(aws s3api create-bucket --bucket "${_bucket}" \
      --region "${AWS_REGION}" \
      --create-bucket-configuration LocationConstraint="${AWS_REGION}" 2>&1); then

      if [[ ! ${_output} =~ "BucketAlreadyExists" ]]; then
        echo "${_output}"
        exit 254
      fi
    fi
  fi
done
