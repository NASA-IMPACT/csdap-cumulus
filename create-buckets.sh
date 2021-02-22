#!/bin/bash

if [ -z "$PREFIX" ]; then
  echo "PREFIX is a required variable, exiting"
  exit 1
fi

AWS_REGION=$(aws configure get region --profile "$AWS_PROFILE")
BUCKET_TYPES="internal private protected public dashboard"

for BUCKET_TYPE in $BUCKET_TYPES
do
  aws s3api create-bucket --bucket "$PREFIX-$BUCKET_TYPE" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"
done
