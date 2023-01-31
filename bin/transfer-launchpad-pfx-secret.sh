#!/usr/bin/env bash

set -Eeuo pipefail

declare secret_id="cumulus-launchpad-pfx"

function usage() {
  echo "Usage: ${0} SRC_AWS_PROFILE DST_AWS_PROFILE"
  echo
  echo "Transfers the AWS secret named '${secret_id}' from the source account"
  echo "to the destination account, where the accounts are specified by their"
  echo "AWS profile names, as defined on your system."
}

function die() {
  echo "ERROR: ${1}" 2>&1
  echo
  usage
  exit 1
}

function main() {
  [[ ${#} == 0 ]] && die "No profiles specified"
  [[ ${#} == 1 ]] && die "Destination profile not specified"
  [[ ${#} != 2 ]] && die "Too many arguments specified"

  declare src_aws_profile=${1}
  declare dst_aws_profile=${2}

  AWS_PROFILE="${src_aws_profile}" aws secretsmanager get-secret-value \
    --secret-id cumulus-launchpad-pfx \
    --output text \
    --query SecretBinary |
    AWS_PROFILE="${dst_aws_profile}" xargs -L1 aws secretsmanager create-secret \
      --name cumulus-launchpad-pfx \
      --secret-binary
}

main "${@}"
