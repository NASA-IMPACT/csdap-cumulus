api_users = [
  "dschuck",
  "kaulfus08"
]

# Trailing slash is required
cumulus_distribution_url    = "https://dy8riyaot0kde.cloudfront.net/"
s3_replicator_target_bucket = "esdis-metrics-inbound-prod-csdap-distribution"
s3_replicator_target_prefix = "input/s3_access/csdapprod"

buckets = {
  internal = {
    name = "<%= expansion('csdap-cumulus-:ENV-internal-:ACCOUNT') %>"
    type = "internal"
  }
  private = {
    name = "<%= expansion('csdap-cumulus-:ENV-private-:ACCOUNT') %>"
    type = "private"
  }
  protected = {
    name = "<%= expansion('csdap-cumulus-:ENV-protected-:ACCOUNT') %>"
    type = "protected"
  }
  public = {
    name = "<%= expansion('csdap-cumulus-:ENV-public-:ACCOUNT') %>"
    type = "public"
  }
  dashboard = {
    name = "<%= expansion('csdap-cumulus-:ENV-dashboard-:ACCOUNT') %>"
    type = "dashboard"
  }
  provider = {
    name = "ss-ingest-prod-ingesteddata-uswest2"
    type = "provider"
  }
}
