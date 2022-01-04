api_users = [
  "dschuck"
]

# Trailing slash is required
cumulus_distribution_url = "https://dy8riyaot0kde.cloudfront.net/"

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
    name = "ss-ingest-dev-ingesteddatac45dd6b6-1w456hbx7scex"
    type = "provider"
  }
}
