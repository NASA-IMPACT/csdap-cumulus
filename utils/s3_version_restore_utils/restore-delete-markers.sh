#!/bin/bash

set -uo pipefail
#set -euo pipefail

# restore-delete-markers.sh

###############################################################################
# Restore S3 objects by removing known delete markers.
#
# This script requires jq to use.
#
# INPUT METHODS
#
# Method 1:
#   ./restore-delete-markers.sh restore.json
#
# Method 2:
#   ./restore-delete-markers.sh '{"bucket":"my-bucket","objects":[...]}'
#
# Optional AWS Profile:
#
#   ./restore-delete-markers.sh restore.json my-profile
#
#   ./restore-delete-markers.sh '{"bucket":"..."}' my-profile
#
#
# Expected JSON Format
# {
#   "bucket": "$BUCKET",
#   "objects": [
#     {
#       "key": "$KEY_PATH",
#       "version_id": "$VERSION_ID"
#     },
#     {
#       // Another Object
#     },
#     {
#       // Another Object etc
#     }
#   ]
# }
#
###############################################################################

# 1000 is the max batch size for AWS S3 batch operations, so we can restore 1000 objects per iteration.
BATCH_SIZE=1000




########################################
# Input validation
########################################

if [[ $# -lt 1 ]]; then
    echo "Usage:"
    echo "  $0 <json-file|json-string> [aws-profile]"
    exit 1
fi

INPUT="$1"

PROFILE="${2:-}"

########################################
# Build optional profile argument
########################################

# AWS_PROFILE_ARGS=()
# if [[ -n "$PROFILE" ]]; then
#     AWS_PROFILE_ARGS+=(--profile "$PROFILE")
# fi


# AWS_PROFILE_ARGS=""
#
# if [[ -n "$PROFILE" ]]; then
#     AWS_PROFILE_ARGS="--profile $PROFILE"
# fi



########################################
# Locate JSON source
########################################

TEMP_JSON=""

if [[ -f "$INPUT" ]]; then

    JSON_FILE="$INPUT"

else

    TEMP_JSON=$(mktemp)

    echo "$INPUT" > "$TEMP_JSON"

    JSON_FILE="$TEMP_JSON"

fi

########################################
# Validation
########################################

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required."
    exit 1
fi

jq empty "$JSON_FILE"

########################################
# Read metadata
########################################

BUCKET=$(jq -r '.bucket' "$JSON_FILE")

TOTAL=$(jq '.objects | length' "$JSON_FILE")

echo
echo "Bucket: $BUCKET"
echo "Objects to restore: $TOTAL"
echo

if [[ "$TOTAL" -eq 0 ]]; then
    echo "Nothing to restore."
    exit 0
fi

########################################
# Process batches
########################################

# Counters for keeping track of the results
TOTAL_SUCCESS=0
TOTAL_NOSUCHVERSION=0
TOTAL_OTHER_ERRORS=0

for ((OFFSET=0; OFFSET<TOTAL; OFFSET+=BATCH_SIZE))
do

    BATCH_FILE=$(mktemp)

    jq \
      --argjson offset "$OFFSET" \
      --argjson size "$BATCH_SIZE" \
      '
      {
        Objects:
        (
          .objects
          | .[$offset:($offset+$size)]
          | map({
              Key: .key,
              VersionId: .version_id
            })
        ),
        Quiet: false
      }
      ' \
      "$JSON_FILE" \
      > "$BATCH_FILE"

    COUNT=$(jq '.Objects | length' "$BATCH_FILE")


    # Non Resumeable Version
    # echo "Processing batch:"
    # echo "  Offset : $OFFSET"
    # echo "  Count  : $COUNT"
    #
    # aws --no-cli-pager s3api delete-objects \
    #     --bucket "$BUCKET" \
    #     "${AWS_PROFILE_ARGS[@]}" \
    #     --delete "file://$BATCH_FILE"
    #
    # rm -f "$BATCH_FILE"
    #
    # echo "Batch complete."
    # echo

    # Resumable Version

    RESPONSE_FILE=$(mktemp)

    echo "Processing batch:"
    echo "  Offset : $OFFSET"
    echo "  Count  : $COUNT"

    # aws --no-cli-pager s3api delete-objects \
    #     --bucket "$BUCKET" \
    #     "${AWS_PROFILE_ARGS[@]}" \
    #     --delete "file://$BATCH_FILE" \
    #     > "$RESPONSE_FILE" 2>&1
    #
    # aws --no-cli-pager s3api delete-objects \
    #     --bucket "$BUCKET" \
    #     $AWS_PROFILE_ARGS \
    #     --delete "file://$BATCH_FILE" \
    #     > "$RESPONSE_FILE" 2>&1
    #
	if [[ -n "$PROFILE" ]]; then

	    aws --no-cli-pager s3api delete-objects \
	        --bucket "$BUCKET" \
	        --profile "$PROFILE" \
	        --delete "file://$BATCH_FILE" \
	        > "$RESPONSE_FILE" 2>&1

	else

	    aws --no-cli-pager s3api delete-objects \
	        --bucket "$BUCKET" \
	        --delete "file://$BATCH_FILE" \
	        > "$RESPONSE_FILE" 2>&1

	fi


    AWS_EXIT_CODE=$?

    if [[ $AWS_EXIT_CODE -ne 0 ]]; then
        echo
        echo "WARNING: AWS CLI returned exit code $AWS_EXIT_CODE"
        echo "Response:"
        cat "$RESPONSE_FILE"
        echo
    fi

    SUCCESS_COUNT=$(jq '.Deleted | length // 0' \
        "$RESPONSE_FILE" 2>/dev/null || echo 0)

    NOSUCHVERSION_COUNT=$(jq '
        [
          .Errors[]?
          | select(.Code=="NoSuchVersion")
        ] | length
    ' "$RESPONSE_FILE" 2>/dev/null || echo 0)

    OTHER_ERROR_COUNT=$(jq '
        [
          .Errors[]?
          | select(.Code!="NoSuchVersion")
        ] | length
    ' "$RESPONSE_FILE" 2>/dev/null || echo 0)

    TOTAL_SUCCESS=$((TOTAL_SUCCESS + SUCCESS_COUNT))
    TOTAL_NOSUCHVERSION=$((TOTAL_NOSUCHVERSION + NOSUCHVERSION_COUNT))
    TOTAL_OTHER_ERRORS=$((TOTAL_OTHER_ERRORS + OTHER_ERROR_COUNT))

    echo "Batch Results:"
    echo "  Restored                : $SUCCESS_COUNT"
    echo "  Already Restored        : $NOSUCHVERSION_COUNT"
    echo "  Other Errors            : $OTHER_ERROR_COUNT"
    echo

    if [[ $OTHER_ERROR_COUNT -gt 0 ]]; then

        echo "Detailed Errors:"

        jq -r '
            .Errors[]?
            | select(.Code!="NoSuchVersion")
            | "  Key=\(.Key)  VersionId=\(.VersionId)  Code=\(.Code)"
        ' "$RESPONSE_FILE" || true

        echo

    fi

    rm -f "$BATCH_FILE"
    rm -f "$RESPONSE_FILE"



done

########################################
# Cleanup
########################################

if [[ -n "$TEMP_JSON" ]]; then
    rm -f "$TEMP_JSON"
fi


# Reporting Section
echo
echo "=============================================="
echo "RESTORE SUMMARY"
echo "=============================================="
echo
echo "Successfully Restored : $TOTAL_SUCCESS"
echo "Already Restored      : $TOTAL_NOSUCHVERSION"
echo "Other Errors          : $TOTAL_OTHER_ERRORS"
echo


echo "Restore process complete."
