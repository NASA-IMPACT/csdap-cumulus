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

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v8.1.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                = var.prefix
  subnet_ids            = data.aws_subnet_ids.ngap_subnets.ids
  include_elasticsearch = var.include_elasticsearch

  elasticsearch_config = var.elasticsearch_config

  tags = {
    Deployment = var.prefix
  }
}
