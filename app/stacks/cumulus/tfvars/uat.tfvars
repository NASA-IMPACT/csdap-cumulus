# <% if in_cba? then %>
# Trailing slash is required
cumulus_distribution_url = "https://9l290b9tv4.execute-api.us-west-2.amazonaws.com/dev/"
# <% else %>
# Trailing slash is required
cumulus_distribution_url = "https://d7yzp0aemakw8.cloudfront.net/"
# <% end %>

s3_replicator_target_bucket = "esdis-metrics-inbound-uat-csdap-distribution"
s3_replicator_target_prefix = "input/s3_access/csdapuat"
