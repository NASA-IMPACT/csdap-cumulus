#!/bin/bash

echo "====="
echo "Welcome to the instance secrets setter!"
echo "====="
echo "Please select the target environment for the secrets:"
echo "IMPORTANT: Ensure you are authenticated with the"
echo "AWS CLI with the appropriate account,"
echo "and using the correct profile."

ENV="uat"
echo "Using the default development $ENV environment!"
echo ""
echo "Please input your STACK_SLUG, usually your personal identifier:"
read stack_slug
echo "Using $stack_slug as your stack slug!"
echo ""

secrets_description=(
    "cmr-username::Earthdata Login (EDL) credentials, username."
    "cmr-password::Earthdata Login (EDL) credentials, password."
    "urs-client-id::Earthdata application client ID."
    "urs-client-password::Earthdata application password for authentication"
)    

echo ""
echo "===="
echo ""

for secret in "${secrets_description[@]}"
do
    secret_name="${secret%%::*}"
    secret_description="${secret##*::}"
    secret_full_path="cumulus/${ENV}-${stack_slug}/$secret_name"
    echo "*** $secret_name ***"
    echo "This is the created secret full path: $secret_full_path"
    echo "Description: $secret_description"
    echo "Please input the value for $secret_name:"
    echo "(or enter Q to skip this secret.)"
    echo ""

    read secret_value

    if [[ "$secret_value" == "Q" || "$secret_value" == "q" || -z "$secret_value" ]]
    then
        echo "Skipping $secret_full_path ..."
        echo ""
        continue
    fi
    create_command="aws secretsmanager create-secret --name '${secret_full_path}' 
    --description '${secret_description}' --secret-string '$secret_value'"

    eval $create_command
    echo ""

done