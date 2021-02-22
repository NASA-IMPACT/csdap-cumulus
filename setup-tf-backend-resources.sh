#!/bin/bash

if [ -z "$PREFIX" ]; then
  echo "PREFIX is a required variable, exiting"
  exit 1
fi

AWS_REGION=$(aws configure get region --profile "$AWS_PROFILE")
STATE_BUCKET="$PREFIX-tf-state"
LOCKS_TABLE="$PREFIX-tf-locks"

aws s3api create-bucket --bucket "$STATE_BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"
aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled

 aws dynamodb create-table \
    --table-name "$LOCKS_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"
