#!/usr/bin/env bash

# Make sure launchpad.pfx file is removed locally even if an error occurs.
trap 'rm -f "${_tmpfile}"' EXIT

set -euo pipefail

# Decode Cumulus Launchpad PFX secret binary key from base64 encoding and write
# it to a temporary file, so we can upload it to S3.

_tmpfile=/tmp/launchpad.pfx

aws secretsmanager get-secret-value \
  --secret-id cumulus-launchpad-pfx \
  --output text \
  --query SecretBinary |
  base64 -d >"${_tmpfile}"

# Upload Cumulus Launchpad PFX file to S3 location expected by Cumulus.

_dest_bucket=csdap-${CUMULUS_PREFIX}-internal
_dest_key=${CUMULUS_PREFIX}/crypto/launchpad.pfx

aws s3 cp "${_tmpfile}" "s3://${_dest_bucket}/${_dest_key}"
