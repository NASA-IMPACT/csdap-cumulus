#!/bin/bash

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
)    

echo ""
echo "===="
echo ""

for secret in "${secrets_description[@]}"
do
    secret_name="${secret%%::*}"
    secret_description="${secret##*::}"
    secret_full_path="cumulus/$ENV/$secret_name"
    echo "*** $secret_name ***"
    echo "This is the created secret full path: $secret_full_path"
    echo "Description: $secret_description"
    echo "Please input the value for $secret_name:"
    echo "(or enter Q to skip this secret.)"
    echo ""

    secrets_match=false
    while [[ $secrets_match != true ]]; do
        read -s secret_value

        if [[ "$secret_value" == "Q" || "$secret_value" == "q" || -z "$secret_value" ]]
        then
            echo "Skipping $secret_full_path ..."
            echo ""
            secrets_match=true
            continue 2
        fi
        echo "Please input the secret value again."
        read -s secret_value_rep

        if [[ $secret_value == $secret_value_rep ]]
        then
            secrets_match=true
        else
            echo "Secrets do not match! Please try again."
        fi

    done

    describe_command="aws secretsmanager describe-secret --secret-id ${secret_full_path}"
    create_command="aws secretsmanager create-secret --name '${secret_full_path}' 
    --description '${secret_description}' --secret-string '$secret_value'"
    put_command="aws secretsmanager put-secret-value --secret-id ${secret_full_path} 
    --secret-string '$secret_value'"

    $describe_command &>/dev/null
    if [ $? == 0 ]
    then
        echo "Secret already exists - updating the value"
        echo $out
        eval $put_command
    else
        echo "Creating secret"
        eval $create_command
    fi
    echo ""

done