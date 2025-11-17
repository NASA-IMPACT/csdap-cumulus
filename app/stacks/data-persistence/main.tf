locals {
  rds_security_group_id      = jsondecode("<%= json_output('rds-cluster.security_group_id') %>")
  rds_user_access_secret_arn = jsondecode("<%= json_output('rds-cluster.user_credentials_secret_arn') %>")
}

module "vpc" {
  source = "../../modules/vpc"
}

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  #elasticsearch_config       = var.elasticsearch_config
  #include_elasticsearch      = var.include_elasticsearch
  permissions_boundary_arn   = local.permissions_boundary_arn
  prefix                     = var.prefix
  rds_security_group_id      = local.rds_security_group_id
  rds_user_access_secret_arn = local.rds_user_access_secret_arn
  subnet_ids                 = module.vpc.subnets.ids
  vpc_id                     = module.vpc.vpc_id

  tags = {
    Deployment = var.prefix
  }
}
