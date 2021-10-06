# Although main.tf uses the Terraspace `output` helper function to obtain
# outputs from module dependencies, the dependencies on the modules are
# not recognized by Terraspace unless the `output` or `depends_on` helper
# function is used in a tfvars file.
#
# While we could use the `output` helper function in this file, that would
# require defining new variables, so we simply use `depends_on` instead.
#
# NOTE: The following lines are commented out only to avoid Terraform syntax
# warnings in editors that recognize Terraform files.  Although they are
# commented out, Terraspace still recognizes the dependencies.

#<% depends_on("data-persistence") %>
#<% depends_on("rds-cluster") %>

cumulus_message_adapter_version = "1.3.0"
csdap_host_url                  = "https://auth.csdap.uat.earthdatacloud.nasa.gov/"

# Unique value used ONLY for distinguishing CMR requests made from this
# deployment from all other CMR requests, in case help is required from the CMR
# support team in debugging CMR issues.
cmr_client_id   = "<%= expansion('csdap-cumulus-:ENV-:ACCOUNT') %>"
cmr_environment = "UAT"
cmr_provider    = "CSDA"

# Make archive API run as a private API gateway and accessible on port 8000
archive_api_port            = 8000
private_archive_api_gateway = true

system_bucket = "<%= expansion('csdap-cumulus-:ENV-internal-:ACCOUNT') %>"

buckets = {
  internal = {
    name = "<%= expansion('csdap-cumulus-:ENV-internal-:ACCOUNT') %>"
    type = "internal"
  }
  private = {
    name = "<%= expansion('csdap-cumulus-:ENV-private-:ACCOUNT') %>"
    type = "private"
  }
  protected = {
    name = "<%= expansion('csdap-cumulus-:ENV-protected-:ACCOUNT') %>"
    type = "protected"
  }
  public = {
    name = "<%= expansion('csdap-cumulus-:ENV-public-:ACCOUNT') %>"
    type = "public"
  }
  dashboard = {
    name = "<%= expansion('csdap-cumulus-:ENV-dashboard-:ACCOUNT') %>"
    type = "dashboard"
  }
  provider = {
    name = "<%= expansion('csdap-cumulus-:ENV-provider-:ACCOUNT') %>"
    type = "provider"
  }
}
