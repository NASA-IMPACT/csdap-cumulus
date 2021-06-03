#!/usr/bin/env bash

set -Eeou pipefail

AWS_REGION=${AWS_REGION:-$(aws configure get region --profile "${AWS_PROFILE}")}
_tf_state_bucket="csdap-${PREFIX}-tf-state"
_tf_locks_table="csdap-${PREFIX}-tf-locks"

# Create the S3 bucket for persisting Terraform state files

aws s3api create-bucket --bucket "${_tf_state_bucket}" \
  --region "${AWS_REGION}" \
  --create-bucket-configuration LocationConstraint="${AWS_REGION}"
aws s3api put-bucket-versioning \
  --bucket "${_tf_state_bucket}" \
  --versioning-configuration Status=Enabled

# Create the DynamoDB table for managing locks on the Terraform state files

aws dynamodb create-table \
  --table-name "${_tf_locks_table}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}"

# Create the S3 buckets used by Cumulus.  These must match the `buckets`
# variable in `cumulus-tf/terraform.tfvars`.

for _bucket_type in internal private protected public dashboard; do
  aws s3api create-bucket --bucket "csdap-${PREFIX}-${_bucket_type}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}"
done

# Create AWS Secrets Manager Secret for Thin Egress App JWT keys
# See https://github.com/asfadmin/thin-egress-app#jwt-cookie-secret

_ssh_dir=${HOME}/.ssh
_keyfile=${_ssh_dir}/thin-egress-app-jwt-cookie.key

if [[ ! -f ${_keyfile} ]]; then
  # shellcheck disable=SC2174
  mkdir -p -m 0700 "${_ssh_dir}"
  ssh-keygen -q -t rsa -b 4096 -m PEM -f "${_keyfile}"
fi

aws secretsmanager create-secret \
  --region "${AWS_REGION}" \
  --name "csdap-${PREFIX}-thin-egress-app-jwt-keys" \
  --description "RS256 keys for Thin Egress App JWT cookies" \
  --secret-string "{\"rsa_priv_key\":\"$(openssl base64 -in "${_keyfile}" -A)\",\"rsa_pub_key\":\"$(openssl base64 -in "${_keyfile}.pub" -A)\"}"

# Create tf/tfvars files, automatically substituting AWS_REGION and PREFIX to
# minimize errors due to manual edits.

declare -a _tf_files=(
  "cumulus-tf/terraform.tf"
  "cumulus-tf/terraform.tfvars"
  "data-persistence-tf/terraform.tf"
  "data-persistence-tf/terraform.tfvars"
)

for _tf_file in ${_tf_files[*]}; do
  if [[ -f ${_tf_file} ]]; then
    echo "'${_tf_file}' already exists"
  else
    echo "Creating '${_tf_file}'"
    envsubst <"${_tf_file}.example" >"${_tf_file}"
  fi
done
