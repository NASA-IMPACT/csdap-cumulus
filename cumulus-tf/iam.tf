# temporary workaround for dashboard permissions issue
data "aws_iam_role" "api_gateway_role" {
  depends_on = [module.cumulus]

  name = "${var.prefix}-lambda-api-gateway"
}

data "aws_s3_bucket" "dashboard_bucket" {
  bucket = var.buckets.dashboard.name
}

data "aws_iam_policy_document" "lambda_api_access_dashboard_bucket" {
  statement {
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucket*",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket*",
      "s3:PutAccelerateConfiguration",
      "s3:PutBucket*",
      "s3:PutLifecycleConfiguration",
      "s3:PutReplicationConfiguration"
    ]
    resources = [
      data.aws_s3_bucket.dashboard_bucket.arn
    ]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject*",
      "s3:ListMultipartUploadParts",
      "s3:PutObject*"
    ]
    resources = [
      "${data.aws_s3_bucket.dashboard_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_api_gateway_access_dashboard_bucket" {
  name   = "${var.prefix}-access-dashboard-bucket"
  role   = data.aws_iam_role.api_gateway_role.id
  policy = data.aws_iam_policy_document.lambda_api_access_dashboard_bucket.json
}
