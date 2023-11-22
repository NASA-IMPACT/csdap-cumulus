#!/usr/bin/env bash

# Make sure launchpad.pfx file is removed locally even if an error occurs.
trap 'rm -f "${_launchpad_pfx_base64}"' EXIT

set -euo pipefail

declare _launchpad_pfx_base64=/tmp/launchpad.pfx.txt

function usage() {
  echo "Usage: ${0} LAUNCHPAD_PFX"
  echo
  echo "Updates the Launchpad certificate and passphrase/code that Cumulus uses"
  echo "for obtaining Launchpad tokens for auth to publish metadata to the CMR."
  echo
  echo "LAUNCHPAD_PFX is the path to the new launchpad.pfx certificate file to"
  echo "be used, and you will be prompted for the associated passphrase/code."
}

function die() {
  echo "ERROR: ${1}" 2>&1
  echo
  usage
  exit 1
}

function main() {
  [[ ${#} -eq 0 ]] && die "No Launchpad certificate file (.pfx) specified"
  [[ ${#} -gt 1 ]] && die "Too many arguments specified"

  read -r -p "Enter the passphrase/code for the Launchpad certificate file: "
  curl \
    --cert "${1}:${REPLY}" \
    --cert-type P12 https://api.launchpad.nasa.gov/icam/api/sm/v1/gettoken \
    --no-progress-meter >/dev/null

  secret_id=cumulus-launchpad-pfx

  # Convert the Launchpad certificate file to a base64-encoded string written to
  # a temporary file.  This is necessary because Terraform does not support any
  # means of converting a secret binary file to a base64-encoded string, which
  # is required when specifying the contents of a binary S3 object.  It's an odd
  # gap in Terraform's functionality.
  base64 -w 0 "${1}" >"${_launchpad_pfx_base64}"

  # Upsert the Launchpad certificate file as a base64-encoded secret string.
  # This secret is NOT used by Cumulus itself.  Rather, it is simply a convenient
  # Cumulus stack-independent location to store the certificate so that it can
  # be retrieved and written to a Cumulus stack-specific location during deploy.
  if aws secretsmanager describe-secret --secret-id "${secret_id}" >/dev/null 2>&1; then
    aws secretsmanager update-secret \
      --secret-id "${secret_id}" \
      --secret-string "file://${_launchpad_pfx_base64}"
  else
    aws secretsmanager create-secret \
      --name "${secret_id}" \
      --description "Launchpad certificate (base64-encoded) for generating tokens to use for publishing metadata to the CMR" \
      --secret-string "file://${_launchpad_pfx_base64}"
  fi

  aws ssm put-parameter \
    --name /shared/cumulus/launchpad-passphrase \
    --type SecureString \
    --overwrite \
    --value "${REPLY}"
}

main "$@"
