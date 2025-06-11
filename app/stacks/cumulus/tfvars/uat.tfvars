#
# See also:
#
# - config/terraform/tfvars/base.tfvars
# - app/stacks/cumulus/tfvars/base.tfvars
#

csdap_host_url = "https://auth.csdap.uat.earthdatacloud.nasa.gov/"

# Trailing slash is required
cumulus_distribution_url = "https://data.csdap.uat.earthdata.nasa.gov/"

metrics_es_host = "https://dmzza2al43z4f.cloudfront.net/"

s3_replicator_target_bucket = "cloud-metrics-inbound-uat-csdap-distribution"
s3_replicator_target_prefix = "input/s3_access/csdapuat"

urs_url = "https://uat.urs.earthdata.nasa.gov"
