resource "random_password" "db_password" {
  length  = 50
  upper   = true
  special = false
}

module "vpc" {
  source = "../../modules/vpc"
}

module "rds_cluster" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus-rds.zip"

  cluster_identifier       = "${var.prefix}-rds-serverless"
  db_admin_password        = random_password.db_password.result
  db_admin_username        = "postgres"
  deletion_protection      = true
  engine_version           = "11.13"
  parameter_group_family   = "aurora-postgresql11"
  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  provision_user_database  = true
  rds_user_password        = random_password.db_password.result
  region                   = data.aws_region.current.name
  snapshot_identifier      = null
  subnets                  = module.vpc.subnets.ids
  tags                     = { Deployment = var.prefix }
  vpc_id                   = module.vpc.vpc_id
}
