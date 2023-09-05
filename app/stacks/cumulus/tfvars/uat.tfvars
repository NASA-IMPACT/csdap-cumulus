#
# See also:
#
# - config/terraform/tfvars/base.tfvars
# - app/stacks/cumulus/tfvars/base.tfvars
#

csdap_host_url = "https://auth.csdap.uat.earthdatacloud.nasa.gov/"

# <% if in_cba? then %>
# Trailing slash is required
cumulus_distribution_url = "https://data.csdap.uat.earthdata.nasa.gov/"
# <% else %>
# Trailing slash is required
cumulus_distribution_url = "https://data.csda.uat.earthdata.nasa.gov/"
# <% end %>

metrics_es_host = "https://dmzza2al43z4f.cloudfront.net/"

# <% if in_cba? then %>
s3_replicator_target_bucket = "cloud-metrics-inbound-uat-csdap-distribution"
# <% else %>
s3_replicator_target_bucket = "esdis-metrics-inbound-uat-csdap-distribution"
# <% end %>

s3_replicator_target_prefix = "input/s3_access/csdapuat"

# Orca Integration
db_admin_password = ""   # TODO - Maybe Needs to be done in SSM
db_user_password = ""
dlq_subscription_email = ""
orca_default_bucket = ""
orca_reports_bucket_name = ""
rds_security_group_id = ""
