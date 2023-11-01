# <% if !in_sandbox? then %>
data "aws_iam_policy_document" "allow_s3_access_logging" {
  statement {
    sid    = "AllowS3AccessLogging"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::${var.system_bucket}/*"]
  }
}
# <% end %>

# Additional permissions required in order to allow Step Functions to include
# Distributed Map states.
# See https://docs.aws.amazon.com/step-functions/latest/dg/use-dist-map-orchestrate-large-scale-parallel-workloads.html#dist-map-permissions
data "aws_iam_policy_document" "allow_sfn_distributed_maps" {
  statement {
    effect = "Allow"
    actions = [
      "states:DescribeExecution",
      "states:StartExecution",
      "states:StopExecution",
    ]
    resources = ["*"]
  }
}

# Associate permissions above with a policy
resource "aws_iam_policy" "allow_sfn_distributed_maps" {
  name        = "${var.prefix}-additional-step-policy"
  description = "Allows Step Functions to include Distributed Map states"
  policy      = data.aws_iam_policy_document.allow_sfn_distributed_maps.json
}

# Attach policy above to the role that Cumulus assigns to Step Functions, so we can
# add Distributed Map states to Step Functions.
resource "aws_iam_role_policy_attachment" "allow_sfn_distributed_maps" {
  # Ideally, the role would be referenced via the Terraform resource address, but I
  # cannot tell if it is not accessible to us here, or if I simply cannot determine
  # the correct way to address it.  The address module.cumulus.step.id doesn't work,
  # so I simply grabbed the value "${var.prefix}-steprole" from the Cumulus source file.
  # See https://github.com/nasa/cumulus/blob/v13.4.0/tf-modules/ingest/iam.tf#L56
  role       = "${var.prefix}-steprole"
  policy_arn = aws_iam_policy.allow_sfn_distributed_maps.arn
}

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
