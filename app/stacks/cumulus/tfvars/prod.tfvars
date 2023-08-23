#
# See also:
#
# - config/terraform/tfvars/base.tfvars
# - app/stacks/cumulus/tfvars/base.tfvars
#

cmr_environment = "OPS"

csdap_host_url = "https://auth.csdap.earthdatacloud.nasa.gov/"

# <% if in_cba? then %>
# Trailing slash is required
cumulus_distribution_url = "https://data.csdap.earthdata.nasa.gov/"
# <% else %>
# Trailing slash is required
cumulus_distribution_url = "https://data.csda.earthdata.nasa.gov/"
# <% end %>

metrics_es_host = "https://d23fzndssjmbvi.cloudfront.net/"

# <% if in_cba? then %>
s3_replicator_target_bucket = "cloud-metrics-inbound-prod-csdap-distribution"
# <% else %>
s3_replicator_target_bucket = "esdis-metrics-inbound-prod-csdap-distribution"
# <% end %>

s3_replicator_target_prefix = "input/s3_access/csdapprod"
