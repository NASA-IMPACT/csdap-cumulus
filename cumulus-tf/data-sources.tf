
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "data_persistence" {
  backend   = "s3"
  config    = var.data_persistence_remote_state_config
  workspace = terraform.workspace
}

resource "random_string" "token_secret" {
  length = 32
  special = true
}

data "aws_ssm_parameter" "ecs_image_id" {
  name = "image_id_ecs_amz2"
}

data "aws_vpc" "ngap_vpc" {
  tags = {
    Name = "Application VPC"
  }
}

data "aws_subnet_ids" "ngap_subnets" {
  vpc_id = data.aws_vpc.ngap_vpc.id

  filter {
    name   = "tag:Name"
    values = ["Private application *"]
  }
}

data "aws_subnet_ids" "ngap_subnets" {
  vpc_id = data.aws_vpc.ngap_vpc.id

  filter {
    name   = "tag:Name"
    values = ["Private application *"]
  }
}

data "aws_iam_role" "ngap_permissions_boundary" {
  name = var.permissions_boundary_name
}
