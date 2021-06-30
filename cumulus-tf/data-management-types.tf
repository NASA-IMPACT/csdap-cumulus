# See https://nasa.github.io/cumulus/docs/configuration/data-management-types

# ------------------------------------------------------------------------------
# IMPORTANT
# ------------------------------------------------------------------------------
# This is an interim solution for getting Collection definition files up to S3.
# Ideally, we probably want to trigger Cumulus API calls to upsert all
# provider, collection, and rule files from the src/data/* directories.
# ------------------------------------------------------------------------------

locals {
  collections_dir = "${path.module}/../src/data/collections"
}

resource "aws_s3_bucket_object" "collection" {
  for_each = fileset(local.collections_dir, "*.json")
  bucket   = data.aws_s3_bucket.system_bucket.id
  key      = "${var.prefix}/collections/${each.value}"
  source   = "${local.collections_dir}/${each.value}"
}
