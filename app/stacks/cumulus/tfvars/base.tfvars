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
