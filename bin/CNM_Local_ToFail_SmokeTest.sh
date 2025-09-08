#!/usr/bin/env bash

# CNM_Local_ToFail_SmokeTest.sh

# This test is designed to be used to make sure that the local topics can receive a failed signal.
# The specific use case for this is to run it in PROD but not actually ingest any data (we do not want to overwrite any real production data).


echo ""
echo "Running CNM_Local_ToFail_SmokeTest.sh -- Note, this test should work in all environments."
echo "The purpose of this test is to send a small message to the local submission topic, verify that the state machine fails, then verify that a 'fail' response topic message was sent."
echo "On advantage to this test is that we can see that the PROD CNM topic communication connections are functioning properly."
echo ""

# Access the CUMULUS_PREFIX environment variable
TOPIC_PREFIX=$CUMULUS_PREFIX  # Example: 'cumulus-kris-sbx7894'

# Hard Coded Submission Topic Suffix # Verify in the TF files
TOPIC_SUFFIX="-cnm-submission-topic"

# Construct the full topic name using the prefix and a suffix (if needed)
# For example, if your topic name is "my-topic-name" and CUMULUS_PREFIX is "dev",
# the full topic name would be "dev-my-topic-name".
TOPIC_NAME="${TOPIC_PREFIX}${TOPIC_SUFFIX}" # Topic Name Example: "cumulus-kris-sbx7894-cnm-submission-topic"

# Get the ARN for the SNS topic using the aws cli command # Should output the entire arn
TOPIC_ARN=$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':${TOPIC_NAME}')].TopicArn" --output text)
          # aws sns list-topics --query "Topics[?ends_with(TopicArn, ':cumulus-kris-sbx7894-cnm-submission-topic')].TopicArn" --output text

# Print the ARN (to verify)
echo "The ARN for the topic '${TOPIC_NAME}' is: ${TOPIC_ARN}"


# Send a fake address
URI_ROOT="s3://not-an-actual-bucket"

# # Set the URI Root -- Default is Sandbox
# URI_ROOT="s3://csda-${CUMULUS_PREFIX}-provider-7894"

# # Are we in UAT?
# # If we are in uat env, then set the uri root to the UAT env
# if [ "$TS_ENV" = "uat" ]; then
#   URI_ROOT="s3://csda-${CUMULUS_PREFIX}-cnm-test-1686" # csda-cumulus-uat-cnm-test-1686
# fi


# Print the URI Root as an extra confirmation so the user can confirm if they are in Sandbox or UAT
echo "URI_ROOT is: '${URI_ROOT}'"

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
        }]
    }
}
EOF
)






# Publish the JSON message to the SNS topic
PUBLISH_COMMAND="aws sns publish --topic-arn \"${TOPIC_ARN}\" --message \"${JSON_MESSAGE}\" --subject \"Cumulus CNM_Local_ToFail_SmokeTest\""
aws sns publish --topic-arn "${TOPIC_ARN}" --message "${JSON_MESSAGE}" --subject "Cumulus CNM_Local_ToFail_SmokeTest" # : $(date -u +%Y-%m-%dT%H:%M:%SZ)"


echo ""
echo "Published JSON message to topic: ${TOPIC_NAME}"
echo ""
echo "  The Entire command including the Published JSON Message: ${PUBLISH_COMMAND}"
echo ""

echo "To verify the Operation of this Smoke Test: log into the AWS account and look at the expected state machine(s) to see if it started (and failed)"
echo "In Sandbox and UAT, check email for both local submission and response topics (note, you have to subscribe to the topics with email to see this)"
echo "In PROD, there should be a lambda hooked up to the local response topic which should simply print data to it's cloud watch log group.  Look for that log output as a verification."
echo ""
