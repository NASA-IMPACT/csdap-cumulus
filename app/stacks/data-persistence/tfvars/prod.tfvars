# Although main.tf uses the Terraspace `output` helper function to obtain
# outputs from the rds-cluster module, the dependency on that module is
# not recognized by Terraspace unless the `output` or `depends_on` helper
# function is used in a tfvars file.
#
# While we could use the `output` helper function in this file, that would
# require defining new variables, so we simply use `depends_on` instead.
#
# NOTE: The following line is commented out only to avoid Terraform syntax
# warnings in editors that recognize Terraform files.  Although it is commented
# out, Terraspace still recognizes the dependency.
#<% depends_on("rds-cluster") %>

elasticsearch_config = {
  domain_name    = "es"
  instance_count = 4
  instance_type  = "r5.large.elasticsearch"
  version        = "5.3"
  volume_type    = "gp2"
  volume_size    = 500
}
