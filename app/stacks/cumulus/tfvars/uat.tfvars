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
