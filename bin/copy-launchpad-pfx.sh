#!/usr/bin/env bash

set -euo pipefail

_src_bucket=csdap-uat-internal
_src_key=cumulus-uat/crypto/launchpad.pfx
_src_etag=$(
  aws s3api head-object \
    --bucket "${_src_bucket}" \
    --key "${_src_key}" \
    --query ETag \
    --output text
)

_dest_bucket=csdap-${CUMULUS_PREFIX}-internal
_dest_key=${CUMULUS_PREFIX}/crypto/launchpad.pfx
_dest_etag=$(
  aws s3api head-object \
    --bucket "${_dest_bucket}" \
    --key "${_dest_key}" \
    --query ETag \
    --output text 2>&1
)

if [[ "${_dest_etag}" != "${_src_etag}" ]]; then
  aws s3api copy-object \
    --copy-source "${_src_bucket}/${_src_key}" \
    --bucket "${_dest_bucket}" \
    --key "${_dest_key}"
fi
