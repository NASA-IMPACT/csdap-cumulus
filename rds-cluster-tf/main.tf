terraform {
  required_version = "0.13.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

# TODO: Pull the data.awc_vpc.ngap_vpc and data.aws_subnet_ids.ngap_subnets out
# of this file and out of the main.tf files for the cumulus and data-persistence
# modules and into a separate vpc module, and have all other modules reference
# the new vpc module, rather than duplicating these everywhere.

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

resource "random_password" "db_password" {
  length  = 50
  upper   = true
  special = false
}

locals {
  permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary_name}"
}

module "rds_cluster" {
  source = "https://github.com/nasa/cumulus/releases/download/v9.1.0/terraform-aws-cumulus-rds.zip"

  cluster_identifier       = "${var.prefix}-rds-serverless"
  db_admin_password        = random_password.db_password.result
  db_admin_username        = var.db_admin_username
  deletion_protection      = var.deletion_protection
  engine_version           = var.engine_version
  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  provision_user_database  = var.provision_user_database
  rds_user_password        = random_password.db_password.result
  region                   = data.aws_region.current.name
  snapshot_identifier      = var.snapshot_identifier
  subnets                  = data.aws_subnet_ids.ngap_subnets.ids
  tags                     = merge(var.tags, { Deployment = var.prefix })
  vpc_id                   = data.aws_vpc.ngap_vpc.id
}
