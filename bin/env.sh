#!/usr/bin/env bash

set -Eeu

_script_dir=$(dirname "${BASH_SOURCE[0]}")
_dotenv_file="$(realpath -s "${_script_dir}/../.env")"

if [[ ! -f ${_dotenv_file} ]]; then
  echo ""
  echo "ERROR: file not found: ${_dotenv_file}"
  echo ""
  exit 1
fi

# shellcheck source=/dev/null
source "${_dotenv_file}"

# Although these variables are not substituted anywhere, we reference them in
# order to generate an error if any one of them is unbound or empty.
echo "${AWS_ACCESS_KEY_ID:?unbound or empty variable}" >/dev/null
echo "${AWS_SECRET_ACCESS_KEY:?unbound or empty variable}" >/dev/null

#-------------------------------------------------------------------------------
# DEFAULT VALUES FOR ENVIRONMENT VARIABLES
#-------------------------------------------------------------------------------
# DO NOT OVERRIDE DEFAULTS BY MODIFYING THIS FILE.  Instead, to override a
# default value, set the override in your `.env` file.  All variables set in
# your `.env` file take precedence over the default values in this file.
#-------------------------------------------------------------------------------
# DO NOT INCLUDE SENSITIVE VALUES IN THIS FILE.  This file is committed to
# source control.  However, your `.env` file is not committed to source control,
# so sensitive values should be placed there instead.
#-------------------------------------------------------------------------------

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
export AWS_REGION=${AWS_REGION:-${AWS_DEFAULT_REGION}}

# Prefix for AWS resource names, which should incorporate your `stack_slug`,
# which you must set in your `.env` file.

export PREFIX=${PREFIX:-cumulus-${STACK_SLUG}}

## S3 buckets that Cumulus requires access to for various operations.

export BUCKET_PREFIX="${BUCKET_PREFIX:-csdap-${PREFIX}}"

export BUCKETS_INTERNAL=${BUCKETS_INTERNAL:-${BUCKET_PREFIX}-internal}
export BUCKETS_PRIVATE=${BUCKETS_PRIVATE:-${BUCKET_PREFIX}-private}
export BUCKETS_PROTECTED=${BUCKETS_PROTECTED:-${BUCKET_PREFIX}-protected}
export BUCKETS_PUBLIC=${BUCKETS_PUBLIC:-${BUCKET_PREFIX}-public}
export BUCKETS_DASHBOARD=${BUCKETS_DASHBOARD:-${BUCKET_PREFIX}-dashboard}
export BUCKETS_PROVIDER=${BUCKETS_PROVIDER:-csdap-cumulus-test-data-bucket}
export BUCKETS_DOWNLOAD=${BUCKETS_DOWNLOAD:-csdap-uat-protected}

# S3 bucket used for Cumulus internal system operations.  This must be the value
# of one of the bucket variables listed above, typically the same value as the
# `buckets_internal` variable.

export SYSTEM_BUCKET=${SYSTEM_BUCKET:-${BUCKET_PREFIX}-internal}

# S3 bucket used for persisting Terraform state files

export TERRAFORM_BACKEND_BUCKET=${TERRAFORM_BACKEND_BUCKET:-${BUCKET_PREFIX}-tf-state}
export TERRAFORM_BACKEND_KEY_PREFIX=${TERRAFORM_BACKEND_KEY_PREFIX:-}

# DynamoDB table used for managing exclusive access locks on the Terraform
# state files.

export TERRAFORM_BACKEND_DYNAMODB_TABLE=${PREFIX}-tf-locks

# Use all arguments to execute an arbitrary command
"$@"
