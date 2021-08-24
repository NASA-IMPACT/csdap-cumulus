# Docs: https://www.terraform.io/docs/providers/aws/index.html
#
# If AWS_PROFILE and AWS_REGION are set, then the provider is optional.
# Here's an example anyway:
#
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}
