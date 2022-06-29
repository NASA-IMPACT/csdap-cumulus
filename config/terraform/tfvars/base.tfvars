aws_region = "<%= expansion(':REGION') %>"

#
# This value is duplicated in the following places.  When making a change, you
# must make the appropriate change in ALL locations:
#
# - Dockerfile (CUMULUS_PREFIX)
# - app/stacks/cumulus/config/hooks/terraform.rb (function_name)
# - config/terraform/tfvars/base.tfvars (prefix)
#
prefix = "<%= expansion('cumulus-:ENV') %>"
