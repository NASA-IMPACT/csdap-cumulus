# UAT was deployed before the 'cumulus-:ENV' convention was in place (see
# base.tfvars), so this preserves the original prefix for UAT to avoid having to
# destroy and recreate the deployment.
prefix = "csdap-uat"
