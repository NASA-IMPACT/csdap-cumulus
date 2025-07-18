#-------------------------------------------------------------------------------
# SSM Parameters
#-------------------------------------------------------------------------------
# For sensitive configuration values, we use SecureString SSM Parameters rather
# than Terraform variables so that we do not commit such sensitive values to
# this repository, thus exposing them.
#
# If planning or deployment fails due to a missing SSM Parameter, use the
# following AWS CLI command to set the missing parameter, where <NAME> is the
# name of the missing parameter and <VALUE> is the desired value:
#
#   aws ssm put-parameter --type SecureString --name <NAME> --value <VALUE>
#
# If you do not know the correct value for a parameter, ask a team member or the
# Project Lead or Manager.  See individual comments below for more details.
#
# You may use the following command to check the value of an existing parameter:
#
#   aws ssm get-parameter --with-decryption --name <NAME>
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# SSM Parameters required across ALL environments
#-------------------------------------------------------------------------------

# CSDAP Launchpad passphrase for using launchpad.pfx for publishing to the CMR
data "aws_ssm_parameter" "launchpad_passphrase" {
  name = "/shared/cumulus/launchpad-passphrase"
}

# CSDAP Cognito Client ID for distribution/download from protected bucket
#
# NOTE: The host corresponding to this client ID (and associated password below)
# is set via the Terraform variable named csdap_host_url.
#
# NOTE: For sandbox environments, the value doesn't matter (it isn't used), so
# you can set this parameter to any non-sensitive value, such as "N/A".
# Unfortunately, Cumulus requires a value for this, even when it isn't used, so
# we're forced to set a dummy value in our sandbox.
#
data "aws_ssm_parameter" "csdap_client_id" {
  name = "/shared/cumulus/csdap-client-id"
}

# CSDAP Cognito Client Password for distribution/download from protected bucket
#
# NOTE: For sandbox environments, the value doesn't matter (it isn't used), so
# you can set this parameter to any non-sensitive value, such as "N/A".
# Unfortunately, Cumulus requires a value for this, even when it isn't used, so
# we're forced to set a dummy value in our sandbox.
#
data "aws_ssm_parameter" "csdap_client_password" {
  name = "/shared/cumulus/csdap-client-password"
}

# ORCA Bucket Access
#
# Currently, the buckets must be setup in the Disaster Recovery (DR) AWS
# accounts.  There are only DR AWS accounts for CBA UAT and CBA PROD.
#
# Unfortunately, this parameter must be refreshed every time these keys expire.
# To refresh, do the following:
#
# 1. Make new long-term access keys
# 2. For each environment, run the following
#
#    DOTENV=<.env file for UAT or Prod> make bash
#    aws ssm put-parameter --name ACCESS_NAME --overwrite --value NEW_ACCESS_KEY
#    aws ssm put-parameter --name SECRET_NAME --overwrite --value NEW_SECRET_KEY
#
# where ACCESS_NAME and SECRET_NAME are the `name` values in the respective
# SSM parameters below, and NEW_ACCESS_KEY and NEW_SECRET_KEY are the new
# values, respectively.

data "aws_ssm_parameter" "orca_s3_access_key" {
  name = "/shared/cumulus/orca/dr/s3-access-key"
}

data "aws_ssm_parameter" "orca_s3_secret_key" {
  name = "/shared/cumulus/orca/dr/s3-secret-key"
}

#-------------------------------------------------------------------------------
# SSM Parameters required across ONLY non-sandbox (non-dev) environments
#-------------------------------------------------------------------------------

# <% if !in_sandbox? then %>

# ESDIS Metrics CloudWatch Logs Destination ARN for replicating S3 access logs
data "aws_ssm_parameter" "log_destination_arn" {
  name = "/shared/cumulus/log-destination-arn"
}

# ESDIS Metrics Elasticsearch Username for ingestion metrics
#
# NOTE: The host corresponding to this username (and associated password below)
# is set via the Terraform variable named metrics_es_host.
#
data "aws_ssm_parameter" "metrics_es_username" {
  name = "/shared/cumulus/metrics-es-username"
}

# ESDIS Metrics Elasticsearch Password for ingestion metrics
data "aws_ssm_parameter" "metrics_es_password" {
  name = "/shared/cumulus/metrics-es-password"
}

# ESDIS Metrics AWS Account ID for allowing Metrics to subscribe to SNS topics
data "aws_ssm_parameter" "metrics_aws_account_id" {
  name = "/shared/cumulus/metrics-aws-account-id"
}

# <% end %>

#-------------------------------------------------------------------------------
# SSM Parameters automatically set by NGAP
#-------------------------------------------------------------------------------
# These are automatically populated by NGAP, so we never have to worry about
# manually setting a value for these parameters ourselves.  If planning or
# deployment fails because any of these SSM Parameters do not exist, reach out
# to the NGAP team since they are responsible for setting them.
#-------------------------------------------------------------------------------

data "aws_ssm_parameter" "ecs_image_id" {
  name = "/ngap/amis/image_id_ecs_al2023_x86"
}
