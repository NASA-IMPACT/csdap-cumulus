# NOTE: The following line is commented out only to avoid Terraform syntax
# warnings in editors that recognize Terraform files.  Although it is commented
# out, Terraspace still recognizes the dependency.
# This ensures that the resources to be modified will exist before attempting to modify them!
#
# During a sandbox deploy, this line above appeared to not work.
# Leaving it here to match the pattern of the other main.tf files
# Also, created a new config/stacks.rb file to define the order of modules.
#
# Note: I found out that this line below must be in this .tfvars file, putting it inside the main.tf file does not work.
# # Also adding stacks.rb files to the modules does not work either.
#
#<% depends_on("cumulus") %>
