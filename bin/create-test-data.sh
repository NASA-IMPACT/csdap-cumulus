#!/usr/bin/env bash

set -euo pipefail

declare provider_bucket
declare files
declare output

echo -n "Determining provider bucket..."
provider_bucket="$(
  echo 'var.buckets["provider"]["name"]' |
    terraspace console cumulus 2>/dev/null |
    grep "${CUMULUS_PREFIX}" |
    sed -E 's/"(.+)"/\1/'
)"
echo "${provider_bucket}"

echo -n "Generating dummy granule files based on cmr.json files..."
files=$(YARN_SILENT=1 yarn generate-test-granule-files)
echo "done"
echo "New or updated files: ${files}"

echo -n "Syncing dummy files to provider bucket ${provider_bucket}..."
output=$(aws s3 sync app/stacks/cumulus/resources/granules "s3://${provider_bucket}" --delete)
echo "done"
echo "${output}"
