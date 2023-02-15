#!/usr/bin/env bash

# Make sure launchpad.pfx file is removed locally even if an error occurs.
trap 'rm -f "${_tmpfile}"' EXIT

set -euo pipefail

declare _tmpfile=/tmp/launchpad.pfx
declare _dest_key=${CUMULUS_PREFIX}/crypto/launchpad.pfx

function usage() {
  echo "Usage: ${0} BUCKET"
  echo
  echo "Writes the 'cumulus-launchpad-pfx' secret to the specified"
  echo "S3 bucket, at the key ${_dest_key}."
}

function die() {
  echo "ERROR: ${1}" 2>&1
  echo
  usage
  exit 1
}

function main() {
  [[ ${#} -eq 0 ]] && die "No S3 bucket specified"
  [[ ${#} -gt 1 ]] && die "Too many arguments specified"

  # Decode Cumulus Launchpad PFX secret binary key from base64 encoding and
  # write it to a temporary file, so we can upload it to S3.

  aws secretsmanager get-secret-value \
    --secret-id cumulus-launchpad-pfx \
    --output text \
    --query SecretBinary |
    base64 -d >"${_tmpfile}"

  # Upload Cumulus Launchpad PFX file to S3 location expected by Cumulus.

  aws s3 cp "${_tmpfile}" "s3://${1}/${_dest_key}"
}

main "$@"
