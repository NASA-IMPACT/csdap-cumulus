cmr_environment = "OPS"

# <% if in_cba? then %>
# Trailing slash is required
#cumulus_distribution_url    = "TBD"
# <% else %>
# Trailing slash is required
cumulus_distribution_url = "https://data.csda.earthdata.nasa.gov/"
# <% end %>

s3_replicator_target_bucket = "esdis-metrics-inbound-prod-csdap-distribution"
s3_replicator_target_prefix = "input/s3_access/csdapprod"
