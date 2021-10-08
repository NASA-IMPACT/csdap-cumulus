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
  db_admin_username        = var.db_admin_username
  deletion_protection      = var.deletion_protection
  engine_version           = var.engine_version
  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  provision_user_database  = var.provision_user_database
  rds_user_password        = random_password.db_password.result
  region                   = data.aws_region.current.name
  snapshot_identifier      = var.snapshot_identifier
  subnets                  = module.vpc.subnets.ids
  tags                     = merge(var.tags, { Deployment = var.prefix })
  vpc_id                   = module.vpc.vpc_id
}
