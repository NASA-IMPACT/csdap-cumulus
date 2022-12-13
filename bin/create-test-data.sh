#!/usr/bin/env bash

set -euo pipefail

_provider="planet"
_collection_name="PSScene3Band"
_collection_version="1"
_collection_id="${_collection_name}___${_collection_version}"
_rule="${_collection_id}_SmokeTest"

_bucket_prefix=$(test "${TS_ENV}" == "uat" && echo "csdap-uat-" || echo "csdap-${CUMULUS_PREFIX}-")

echo -n "Upserting provider '${_provider}' ... "
_provider_bucket=${_bucket_prefix}provider
cumulus providers upsert --data '{ "id": "'"${_provider}"'", "protocol": "s3", "host": "'"${_provider_bucket}"'" }' >/dev/null
echo "Done"

echo -n "Upserting collection '${_collection_id}' ... "
cumulus collections upsert --data "app/stacks/cumulus/resources/collections/${_collection_id}.json" >/dev/null
echo "Done"

echo -n "Upserting rule '${_rule}' ... "
cumulus rules upsert --data "app/stacks/cumulus/resources/rules/${_rule}.json" >/dev/null
echo "Done"

# Add sample granule files
_s3_prefix_url="s3://${_provider_bucket}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/"
echo -n "Uploading sample '${_collection_id}' granule files to ${_s3_prefix_url} ... "
aws s3 cp --recursive "app/stacks/cumulus/resources/granules/${_collection_name}" "${_s3_prefix_url}" >/dev/null
echo "Done"

echo
echo "To run a smoke test, do the following:"
echo
echo "1. Open a terminal in a Docker container:"
echo
echo "     make bash"
echo
echo "2. Enable the rule:"
echo
echo "     cumulus rules enable --name ${_rule}"
echo
echo "3. Run the rule to trigger discovery and ingestion:"
echo
echo "     cumulus rules run --name ${_rule}"
echo
echo "4. Follow the logs for discovery to confirm discovery of the uploaded"
echo "   sample granule files (NOTE: it may take a minute or so before you see"
echo "   any logging output):"
echo
echo "     aws logs tail --follow /aws/lambda/${CUMULUS_PREFIX}-DiscoverGranules"
echo
echo "5. Follow the logs for ingestion to confirm CMR validation of the metadata"
echo "   (NOTE: either kill the previous command with Ctrl-C, or open another"
echo "   terminal window and start another Docker container by running 'make bash'):"
echo
echo "     aws logs tail --follow /aws/lambda/${CUMULUS_PREFIX}-PostToCmr"
echo
echo "If you see no output from either of the 'aws logs' commands after a few"
echo "minutes, then you may need to log into the AWS Management Console and check"
echo "for errors in one or both of the following Step Functions:"
echo
echo "  - ${CUMULUS_PREFIX}-DiscoverAndQueueGranules"
echo "  - ${CUMULUS_PREFIX}-IngestAndPublishGranule"
echo
