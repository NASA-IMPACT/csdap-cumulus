#!/usr/bin/env bash

echo "====="
echo "Welcome to the environment secrets setter!"
echo "====="
echo "Please select the target environment for the secrets:"
echo "IMPORTANT: Ensure you are authenticated with the"
echo "AWS CLI with the appropriate account,"
echo "and using the correct profile."

PS3='Please enter your choice: '
options=("UAT" "SIT" "PROD" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "UAT")
            ENV="uat"
            break
            ;;
        "SIT")
            ENV="sit"
            break
            ;;
        "PROD")
            ENV="prod"
            break
            ;;
        "Quit")
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
echo "You have selected the $ENV environment!"

secrets_description=(
    "csdap-client-id::The CSDAP client id."
    "csdap-client-password::The CSDAP client password."
    "csdap-host-url::The CSDAP host url."
)    

echo ""
echo "===="
echo ""

for secret in "${secrets_description[@]}"
do
    secret_name="${secret%%::*}"
    secret_description="${secret##*::}"
    secret_full_path="test-csdap-cumulus/$ENV/$secret_name"
    echo "*** $secret_name ***"
    echo "This is the created secret full path: $secret_full_path"
    echo "Please input the value for $secret_name:"
    echo "(or enter Q to skip this secret.)"
    echo ""

    read secret_value

    if [ "$secret_value" == "Q" ]
    then
        echo "Skipping $secret_full_path ..."
        echo ""
        continue
    fi
    create_command="aws secretsmanager create-secret --name '${secret_full_path}' 
    --description '${secret_description}' --secret-string '$secret_value'"
    echo $create_command
    eval $create_command
    echo ""

done