# Optional variables:
# acl = "private"
region = "<%= expansion(':REGION') %>"

cumulus_message_adapter_version = "1.3.0"
permissions_boundary_name       = "NGAPShRoleBoundary"

prefix = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE') %>"

buckets = {
  internal = {
    name = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-internal') %>"
    type = "internal"
  }
  private = {
    name = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-private') %>"
    type = "private"
  },
  protected = {
    name = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-protected') %>"
    type = "protected"
  },
  public = {
    name = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-public') %>"
    type = "public"
  },
  dashboard = {
    name = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-dashboard') %>"
    type = "dashboard"
  }
}

system_bucket = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-internal') %>"

# The CMR Client-Id is a name for the client using the CMR API.  Specifying this
# helps Operations monitor query performance per client.  It can also make it
# easier for them to identify your requests if you contact them for assistance.
# This can be any value of your choosing since it's sole purpose is to
# distinguish your CMR requests from requests from others.
cmr_client_id = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE') %>"

# CMR credentials are required for writing to the CMR
cmr_username = "<%= aws_secret("csdap-cumulus-#{Terraspace.env}-cmr-username") %>"
cmr_password = "<%= aws_secret("csdap-cumulus-#{Terraspace.env}-cmr-password") %>"

# Earthdata application client ID/password for authentication
# urs_client_id       = "Bq8sund1Ta1MOA8HHaLsHQ"
# urs_client_password = "Fm6QDcT,cx4664JLvh"
urs_client_id       = "<%= aws_secret("csdap-cumulus-#{Terraspace.env}-#{@mod.options.instance}-urs-client-id") %>"
urs_client_password = "<%= aws_secret("csdap-cumulus-#{Terraspace.env}-#{@mod.options.instance}-urs-client-password") %>"

api_users = [
  # Comma-separated list of double-quoted URS usernames of authorized users.
  # Include your own username at a minimum.
  #"myusername"
]

# Name of secret in AWS secrets manager containing SSH keys for signing JWTs
# See https://github.com/asfadmin/thin-egress-app#jwt-cookie-secret
thin_egress_jwt_secret_name = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-thin-egress-app-jwt-keys') %>"

data_persistence_remote_state_config = {
  bucket = "<%= expansion('csdap-cumulus-:ENV-:INSTANCE-tfstate') %>"
  key    = "data-persistence/terraform.tfstate"
  region = "<%= expansion(':REGION') %>"
}

oauth_provider     = "earthdata"
cmr_oauth_provider = "earthdata"

# Make archive API run as a private API gateway and accessible on port 8000
archive_api_port            = 8000
private_archive_api_gateway = true

# Optional

# ecs_cluster_instance_subnet_ids = ["subnet-12345"]

## Optional. Required if using cmr_oauth_provider = "launchpad"
# launchpad_api = "launchpadApi"
# launchpad_certificate = "certificate"
# launchpad_passphrase = "passphrase"

## Optional. Oauth user group to validate the user against when using oauth_provider = "launchpad"
# oauth_user_group = "usergroup"

## Optional.  When using oauth_provider = "launchpad", and if you are configuring Cumulus to authenticate
## the dashboard via NASA's Launchpad SAML implementation.
## see Wiki: https://wiki.earthdata.nasa.gov/display/CUMULUS/Cumulus+SAML+Launchpad+Integration
# saml_entity_id                  = "Configured SAML entity-id"
# saml_assertion_consumer_service = "<Cumulus API endpoint>/saml/auth, e.g. https://example.com/saml/auth"

## Sandbox Launchpad saml2sso: https://auth.launchpad-sbx.nasa.gov/affwebservices/public/saml2sso
## Production Launchpad saml2sso: https://auth.launchpad.nasa.gov/affwebservices/public/saml2sso
# saml_idp_login                  = "nasa's saml2sso endpoint, e.g. https://example.gov/affwebservices/public/saml2sso"

## Sandbox Launchpad IDP metadata: https://auth.launchpad-sbx.nasa.gov/unauth/metadata/launchpad-sbx.idp.xml
## Production Launchpad IDP Metadata: https://auth.launchpad.nasa.gov/unauth/metadata/launchpad.idp.xml
# saml_launchpad_metadata_url     = "url of the identity provider public metadata xml file"

## Optional
# key_name      = "MY-KEY"

## Optional
# metrics_es_host = "xxxxxxxxxx.cloudfront.net"
# metrics_es_username = "user"
# metrics_es_password = "password"

## Optional. Required to send EMS ingest/distribution reports.
# ems_host              = "ems-host.nasa.gov"
# ems_port              = 22
# ems_path              = "/"
# ems_datasource        = "UAT"
# ems_private_key       = "ems-private.pem"
# ems_provider          = "CUMULUS"
# ems_retention_in_days = 30
# ems_submit_report     = true
# ems_username          = "user"

## Optional. Required to send logs to the Metrics ELK stack
# log_api_gateway_to_cloudwatch = false
# log_destination_arn = "arn:aws:logs:us-east-1:1234567890:destination:LogsDestination"
# additional_log_groups_to_elk = {
#  "MyLogs" = "/aws/lambda/my-logs"
# }
