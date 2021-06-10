terraform {
  required_version = "0.13.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
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

data "terraform_remote_state" "rds_cluster" {
  backend   = "s3"
  config    = var.rds_cluster_remote_state_config
  workspace = terraform.workspace
}

locals {
  permissions_boundary_arn   = lookup(data.terraform_remote_state.rds_cluster.outputs, "permissions_boundary_arn", "")
  rds_security_group_id      = lookup(data.terraform_remote_state.rds_cluster.outputs, "security_group_id", "")
  rds_user_access_secret_arn = lookup(data.terraform_remote_state.rds_cluster.outputs, "user_credentials_secret_arn", "")
}

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v9.1.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  elasticsearch_config       = var.elasticsearch_config
  include_elasticsearch      = var.include_elasticsearch
  permissions_boundary_arn   = local.permissions_boundary_arn
  prefix                     = var.prefix
  rds_security_group_id      = local.rds_security_group_id
  rds_user_access_secret_arn = local.rds_user_access_secret_arn
  subnet_ids                 = data.aws_subnet_ids.ngap_subnets.ids
  vpc_id                     = data.aws_vpc.ngap_vpc.id

  tags = {
    Deployment = var.prefix
  }
}
