#!/bin/bash

# Shell script to zip the lambda function to prepare for deployment
# Before zipping, we must replace a few references to the env contained within the
# python code so that this will work in all of our deployment environments.

# Spacer to make the terminal output easier to follow
echo ""

echo "TS_ENV is: $TS_ENV"

# This should extract TS_ENV from the current .envfile
# DOTENV should be available to this script when called from inside the makefile
TSENV_VALUE=$(grep "^TS_ENV=" $DOTENV | cut -d '=' -f 2)  # Examples: kris-sbx7894 or uat or prod
#
# If the TSENV_VALUE is blank, then set try setting it another way
if [ -z "$TSENV_VALUE" ]; then
  TSENV_VALUE=$TS_ENV
  echo "TSENV_VALUE was blank, so set by TS_ENV.  TSENV_VALUE is now set to: $TSENV_VALUE"
fi
#
# If the TSENV_VALUE is STILL blank, then set it to
if [ -z "$TSENV_VALUE" ]; then
  TSENV_VALUE="BLANK"
  echo "TSENV_VALUE was STILL blank, so set by TS_ENV.  TSENV_VALUE is now set to default of: $TSENV_VALUE"
fi

# Output the TSENV value
echo "TSENV_VALUE should be set now.  It is currently set to: $TSENV_VALUE"

CUMULUS_PREFIX_VAR="cumulus-$TSENV_VALUE"
echo "zip_lambdas.sh: CUMULUS_PREFIX_VAR is: $CUMULUS_PREFIX_VAR"

# Current Execution Path
CURRENT_DIR=$(pwd)
#echo "sh zip_lambdas: Current execution path: $CURRENT_DIR"

# Get the full path to the directory where the lambda is located
FULL_PREFIX_PATH="$CURRENT_DIR/app/stacks/post-deploy-mods/resources/lambdas/pre-filter-DistributionApiEndpoints"
#echo "sh zip_lambdas: FULL_PREFIX_PATH: $FULL_PREFIX_PATH"

# File Path Variables
LAMBDA_FILE_ORIGINAL="$FULL_PREFIX_PATH/src/lambda_function.py"
LAMBDA_FILE="$FULL_PREFIX_PATH/distro/lambda_function.py"
ZIP_FILE="$FULL_PREFIX_PATH/distro/lambda.zip"

# First, replace some of the code with the correct prefix
#CUMULUS_PREFIX=$1   # CUMULUS_PREFIX should already be an environment variable
STRING_TO_REPLACE="ENV_VAR__CUMULUS_PREFIX"

echo "zip_lambdas.sh: About to copy $LAMBDA_FILE_ORIGINAL to $LAMBDA_FILE"
cp "$LAMBDA_FILE_ORIGINAL" "$LAMBDA_FILE"
echo "zip_lambdas.sh: About to replace occurrences of $STRING_TO_REPLACE with $CUMULUS_PREFIX_VAR in file: $LAMBDA_FILE"

# Actually do the replacement
awk -v old="$STRING_TO_REPLACE" -v new="$CUMULUS_PREFIX_VAR" '{gsub(old, new); print}' "$LAMBDA_FILE_ORIGINAL" > "$LAMBDA_FILE"
echo "zip_lambdas.sh: Done preparing the correct python file"

# Output to the Terminal
echo "zip_lambdas.sh: About to zip $LAMBDA_FILE"

# Zip the Lambda function
zip -j "$ZIP_FILE" "$LAMBDA_FILE"

# Output to the Terminal
echo "zip_lambdas.sh: Completed.  Zipped Lambda to $ZIP_FILE"
echo ""

