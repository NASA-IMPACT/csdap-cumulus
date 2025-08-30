#!/usr/bin/env bash

# CNM_Remote_SmokeTest.sh

echo ""
echo "Running CNM_Remote_SmokeTest.sh -- Note, this only works in Sandbox and UAT envs"
echo "Also Note: This smoke test simply publishes a message to the REMOTE VERSION of the submission topic which should trigger an ingest and then a subsequent automatic response topic submission after the ingest is completed.  For a quick turn around on this test, subscribe your email to both topics and watch for results.  For a more detailed look, check the state machine for cumulus-ENV-CNMIngestAndPublishGranule, and then check the expected S3 destination bucket for files."
echo ""

# Access the CUMULUS_PREFIX environment variable
TOPIC_PREFIX=$CUMULUS_PREFIX  # Example: 'cumulus-kris-sbx7894'

# Hard Coded Submission Topic Suffix # Verify in the TF files
TOPIC_SUFFIX="-cnm-submission-topic"

# Construct the full topic name using the prefix and a suffix (if needed)
# For example, if your topic name is "my-topic-name" and CUMULUS_PREFIX is "dev",
# the full topic name would be "dev-my-topic-name".
TOPIC_NAME="csda-${TOPIC_PREFIX}${TOPIC_SUFFIX}" # Topic Name Example: "csda-cumulus-kris-sbx7894-cnm-submission-topic"   # csda- is the aws account prefix

# Get the Submission Topic ARN for the SNS topic using the aws cli command # Should output the entire arn
#
# REMOTE_CNM_TOPIC_SUBMISSION_ARN
TOPIC_ARN=$(aws ssm get-parameter --name "/shared/cumulus/remote-cnm-arn-topic-submission" --query "Parameter.Value" --output text) 

# Print the ARN (to verify)
echo "The ARN for the topic '${TOPIC_NAME}' is: ${TOPIC_ARN}"

# Set the URI Root -- Default is Sandbox
URI_ROOT="s3://csda-${CUMULUS_PREFIX}-provider-7894"

# Are we in UAT?
# If we are in uat env, then set the uri root to the UAT env
if [ "$TS_ENV" = "uat" ]; then
  URI_ROOT="s3://csda-${CUMULUS_PREFIX}-cnm-test-1686" # csda-cumulus-uat-cnm-test-1686
fi

# Print the URI Root as an extra confirmation so the user can confirm if they are in Sandbox or UAT
echo "URI_ROOT is: '${URI_ROOT}'"


# Doing PSScene3Band - Granule "20171201_031959_0f31_"
#
# # PSScene3Band Granule File List
#
# 20171201_031959_0f31_1B_Analytic_DN_metadata.xml
# 20171201_031959_0f31_1B_Analytic_DN_RPC.TXT
# 20171201_031959_0f31_1B_Analytic_DN_udm.tif
# 20171201_031959_0f31_1B_Analytic_DN.tif
# 20171201_031959_0f31_1B_Analytic_metadata.xml
# 20171201_031959_0f31_1B_Analytic_RPC.TXT
# 20171201_031959_0f31_1B_Analytic.tif
# 20171201_031959_0f31_3B_Analytic_DN_metadata.xml
# 20171201_031959_0f31_3B_Analytic_DN_udm.tif
# 20171201_031959_0f31_3B_Analytic_DN.tif
# 20171201_031959_0f31_3B_Analytic_metadata.xml
# 20171201_031959_0f31_3B_Analytic.tif
# 20171201_031959_0f31_3B_Visual_metadata.xml
# 20171201_031959_0f31_3B_Visual.tif
# 20171201_031959_0f31_cmr.json
# 20171201_031959_0f31_metadata.json
#
# This IS the message that gets sent to the Submission Topic
# Define a multi-line JSON message using a here-document
#  "WV04_MSI_L1B",
#read -r -d '' JSON_MESSAGE <<-EOF
JSON_MESSAGE=$(cat <<-EOF
{
    "version": "1.5.1",
    "provider": "planet",
    "deliveryTime": "2024-10-12T16:50:23.458100",
    "collection": "PSScene3Band",
    "identifier": "58ac4ab1-22dc-4475-994e-154ee2c5e004",
    "product":
    {
        "name": "PSScene3Band-20171201_031959_0f31",
        "dataVersion": "1",
        "files": [
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Visual_metadata.xml",
            "name": "20171201_031959_0f31_3B_Visual_metadata.xml",
            "size": 15,
            "type": "metadata",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic_metadata.xml",
            "name": "20171201_031959_0f31_1B_Analytic_metadata.xml",
            "size": 15,
            "type": "metadata",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Analytic_DN_udm.tif",
            "name": "20171201_031959_0f31_3B_Analytic_DN_udm.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic_DN_udm.tif",
            "name": "20171201_031959_0f31_1B_Analytic_DN_udm.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic_DN.tif",
            "name": "20171201_031959_0f31_1B_Analytic_DN.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_metadata.json",
            "name": "20171201_031959_0f31_metadata.json",
            "size": 15,
            "type": "metadata",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Analytic_DN.tif",
            "name": "20171201_031959_0f31_3B_Analytic_DN.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic_DN_RPC.TXT",
            "name": "20171201_031959_0f31_1B_Analytic_DN_RPC.TXT",
            "size": 15,
            "type": "ancillary",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic_RPC.TXT",
            "name": "20171201_031959_0f31_1B_Analytic_RPC.TXT",
            "size": 15,
            "type": "ancillary",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic_DN_metadata.xml",
            "name": "20171201_031959_0f31_1B_Analytic_DN_metadata.xml",
            "size": 15,
            "type": "metadata",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Analytic.tif",
            "name": "20171201_031959_0f31_3B_Analytic.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Analytic_metadata.xml",
            "name": "20171201_031959_0f31_3B_Analytic_metadata.xml",
            "size": 15,
            "type": "metadata",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Analytic_DN_metadata.xml",
            "name": "20171201_031959_0f31_3B_Analytic_DN_metadata.xml",
            "size": 15,
            "type": "metadata",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_3B_Visual.tif",
            "name": "20171201_031959_0f31_3B_Visual.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_1B_Analytic.tif",
            "name": "20171201_031959_0f31_1B_Analytic.tif",
            "size": 15,
            "type": "browse",
            "checksum": "e813d94ff840788d8d21f758304a2e7a",
            "checksumType": "MD5"
        },
        {
            "uri": "${URI_ROOT}/storage-ss-ingest-prod-ingesteddata-uswest2/planet/PSScene3Band-20171201_031959_0f31/20171201_031959_0f31_cmr.json",
            "name": "20171201_031959_0f31_cmr.json",
            "size": 11880,
            "type": "metadata",
            "checksum": "aeace20de9fb70278c23fe73c98bcfdec292baf0a403cef28656d8d1623596fd",
            "checksumType": "SHA-256"
        }]
    }
}
EOF
)


# Publish the JSON message to the SNS topic
PUBLISH_COMMAND="aws sns publish --topic-arn \"${TOPIC_ARN}\" --message \"${JSON_MESSAGE}\" --subject \"Cumulus CNM_Remote_SmokeTest\""
aws sns publish --topic-arn "${TOPIC_ARN}" --message "${JSON_MESSAGE}" --subject "Cumulus CNM_Remote_SmokeTest" # : $(date -u +%Y-%m-%dT%H:%M:%SZ)"


echo ""
echo "Published JSON message to topic: ${TOPIC_NAME}"
echo ""
echo "  The Entire command including the Published JSON Message: ${PUBLISH_COMMAND}"
echo ""

echo "To verify the Operation of this Smoke Test: log into the AWS account and look at the expected state machine(s) to see if it started"
echo "To verify the Completion of this Smoke Test: log into the AWS account, look at the expected Destination S3 Bucket - check the dates to see if they are showing a time very near the time of this test execution."
echo "To debug, Look at SNS topic delivery logs in cloudwatch, or go to the Lambda with the name, <env>MessageConsumer in it's name and look at those Cloudwatch logs for details or possible errors/warnings."
echo ""
