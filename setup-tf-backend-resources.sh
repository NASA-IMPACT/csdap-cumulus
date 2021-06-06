#!/usr/bin/env bash

set -Eeou pipefail

# Creates the resources necessary for managing the Terraform state files using
# AWS.  This includes a bucket for persisting the state files, along with a
# DynamoDB table for managing locks on the state files (to avoid simultaneous
# updates).  Versioning is enabled on the bucket to facilitate restoring
# previous versions of state files in the event of corruption.

# shellcheck disable=SC2016
_region="$(echo '${AWS_REGION}' | ./dotenv envsubst)"
# shellcheck disable=SC2016
_tf_state_bucket="$(echo 'csdap-${PREFIX}-tf-state' | ./dotenv envsubst)"
# shellcheck disable=SC2016
_tf_locks_table="$(echo 'csdap-${PREFIX}-tf-locks' | ./dotenv envsubst)"

./dotenv aws s3api create-bucket --bucket "${_tf_state_bucket}" \
  --region "${_region}" \
  --create-bucket-configuration LocationConstraint="${_region}"

./dotenv aws s3api put-bucket-versioning \
  --bucket "${_tf_state_bucket}" \
  --versioning-configuration Status=Enabled

./dotenv aws dynamodb create-table \
  --table-name "${_tf_locks_table}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${_region}"
