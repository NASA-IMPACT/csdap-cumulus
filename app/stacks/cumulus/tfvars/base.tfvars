# Although main.tf uses the Terraspace `output` helper function to obtain
# outputs from module dependencies, the dependencies on the modules are
# not recognized by Terraspace unless the `output` or `depends_on` helper
# function is used in a tfvars file.  See
# https://terraspace.cloud/docs/dependencies/tfvars/considerations/#dependency-must-be-defined-in-tfvars
#
# While we could use the `output` helper function in this file, that would
# require defining new variables, so we simply use `depends_on` instead.
#
# NOTE: The following lines are commented out only to avoid Terraform syntax
# warnings in editors that recognize Terraform files.  Although they are
# commented out, Terraspace still recognizes the dependencies.

#<% depends_on("data-persistence") %>
#<% depends_on("rds-cluster") %>

cmr_environment             = "UAT"
orca_dlq_subscription_email = "csdap@uah.edu"

system_bucket = "<%= bucket('internal') %>"

buckets = {
  # https://nasa.github.io/cumulus-orca/docs/developer/deployment-guide/deployment-s3-bucket/
  orca_reports = {
    name = "<%= %Q[csda-cumulus-cba-#{Terraspace.env == 'prod' ? 'prod' : 'uat'}-orca-reports] %>"
    type = "orca"
  }
  orca_default = {
    name = "<%= %Q[csda-cumulus-cba-#{Terraspace.env == 'prod' ? 'prod' : 'uat'}-orca-archive] %>"
    type = "orca"
  }
  internal = {
    name = "<%= bucket('internal') %>"
    type = "internal"
  }
  private = {
    name = "<%= bucket('private') %>"
    type = "private"
  }
  protected = {
    name = "<%= bucket('protected') %>"
    type = "protected"
  }
  public = {
    name = "<%= bucket('public') %>"
    type = "public"
  }
  dashboard = {
    name = "<%= bucket('dashboard') %>"
    type = "dashboard"
  }
  #-----<% if in_sandbox? then %>
  # Sandbox provider bucket
  provider = {
    name = "<%= bucket('provider') %>"
    type = "provider"
  }
  #-----<% else %>
  # Non-sandbox provider buckets
  planet = {
    name = "ss-ingest-prod-ingesteddata-uswest2"
    type = "provider"
  }
  maxar = {
    name = "csdap-maxar-delivery"
    type = "provider"
  }
  cumulus = {
    name = "csdap-cumulus-prod-protected"
    type = "provider"
  }
  #-----<% end %>
}
