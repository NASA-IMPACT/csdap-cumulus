locals {
  # See https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
  # At above link, expand the collapsed section titled "Regions available before
  # August 2022" to see the list of Elastic Load Balancing account IDs by region.
  # The following map is constructed from that list, but may not be complete, as
  # we don't necessarily need to cover all regions.
  elb_account_ids = {
    "us-east-1" = "127311923021"
    "us-east-2" = "033677994240"
    "us-west-1" = "027434742980"
    "us-west-2" = "797873946194"
  }
  # 797873946194 is the AWS account for Elastic Load Balancing for us-west-2 as
  # shown in the elb_account_ids map above. This is the default value for the
  # lookup function used farther below, as a matter of best practice.
  default_elb_account_id = "797873946194"
}

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

#-------------------------------------------------------------------------------
# Additional permissions required in order to allow Step Functions to include
# Distributed Map states.  This is what allows us to sidestep the 25,000 event-
# transition quota for Step Functions.
#
# See also:
# - https://docs.aws.amazon.com/step-functions/latest/dg/use-dist-map-orchestrate-large-scale-parallel-workloads.html#dist-map-permissions
#-------------------------------------------------------------------------------

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

#-------------------------------------------------------------------------------
# Additional policy required on the system bucket as per ORCA v8.0.0.
#
# See also:
# - https://github.com/nasa/cumulus-orca/releases/tag/v8.0.0
# - https://nasa.github.io/cumulus-orca/docs/developer/deployment-guide/deployment-s3-bucket#bucket-policy-for-load-balancer-server-access-logging
#-------------------------------------------------------------------------------

data "aws_iam_policy_document" "allow_load_balancer_s3_write_access" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${lookup(local.elb_account_ids, data.aws_region.current.name, local.default_elb_account_id)}:root"
      ]
    }
    resources = [
      "arn:aws:s3:::${var.system_bucket}/${var.prefix}-lb-gql-a-logs/AWSLogs/${local.aws_account_id}/*"
    ]
  }
}

# Attach policy above to the system bucket
resource "null_resource" "allow_load_balancer_s3_write_access" {
  triggers = {
    buckets = var.system_bucket
  }

  # Since we do not have Terraform configured to manage our buckets, we cannot
  # ask Terraform to put any policies on the buckets, so we're calling out to
  # the AWS CLI to put the desired policy on our "system" (internal) bucket to
  # allow load balancer logs to be written to it, as required by ORCA.
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-COMMAND
      aws s3api put-bucket-policy \
        --bucket ${var.system_bucket} \
        --policy '${data.aws_iam_policy_document.allow_load_balancer_s3_write_access.json}'
    COMMAND
  }
}

#-------------------------------------------------------------------------------
# Temporary workaround for dashboard permissions issue
#-------------------------------------------------------------------------------

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
