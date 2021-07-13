#!/usr/bin/env bash

set -Eeu

# Creates the resources necessary for managing the Terraform state files using
# AWS.  This includes a bucket for persisting the state files, along with a
# DynamoDB table for managing locks on the state files (to avoid simultaneous
# updates).  Versioning is enabled on the bucket to facilitate restoring
# previous versions of state files in the event of corruption.

if ! aws s3api head-bucket --bucket "${TERRAFORM_BACKEND_BUCKET}"; then
  echo "Creating bucket '${TERRAFORM_BACKEND_BUCKET}'..."

  aws s3api create-bucket --bucket "${TERRAFORM_BACKEND_BUCKET}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}"

  aws s3api put-bucket-versioning \
    --bucket "${TERRAFORM_BACKEND_BUCKET}" \
    --versioning-configuration Status=Enabled
fi

if ! aws dynamodb describe-table --table-name "${TERRAFORM_BACKEND_DYNAMODB_TABLE}" >/dev/null; then
  echo "Creating table '${TERRAFORM_BACKEND_DYNAMODB_TABLE}'..."

  aws dynamodb create-table \
    --table-name "${TERRAFORM_BACKEND_DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"
fi
