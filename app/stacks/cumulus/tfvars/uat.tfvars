api_users = [
  "mattocks",
  "kaulfusa",
  "jsrikish",
  "chuckwondo"
]
# Trailing slash is required
cumulus_distribution_url    = "https://d7yzp0aemakw8.cloudfront.net/"
key_name                    = "csda_uat_cumulus"
s3_replicator_target_bucket = "esdis-metrics-inbound-uat-csdap-distribution"
s3_replicator_target_prefix = "input/s3_access/csdapuat"


#-------------------------------------------------------------------------------
# IMPORTANT
#-------------------------------------------------------------------------------
# Since the UAT deployment was created before a bucket-naming convention was
# established (see base.tfvars), the bucket names used in this file retain the
# "legacy" names for UAT.  We may wish to consider migrating to new buckets that
# adhere to the bucket-naming convention, but to do so would require submitting
# NAMS requests for the dashboard bucket and the protected bucket (fronted by
# CloudFront for distribution).
#-------------------------------------------------------------------------------

system_bucket = "csdap-uat-internal"

buckets = {
  internal = {
    name = "csdap-uat-internal"
    type = "internal"
  }
  private = {
    name = "csdap-uat-private"
    type = "private"
  }
  protected = {
    name = "csdap-uat-protected"
    type = "protected"
  }
  public = {
    name = "csdap-uat-public"
    type = "public"
  }
  dashboard = {
    name = "csdap-uat-dashboard"
    type = "dashboard"
  }
  planet = {
    name = "ss-ingest-prod-ingesteddata-uswest2"
    type = "provider"
  }
  maxar = {
    name = "csdap-maxar-delivery"
    type = "provider"
  }
}
