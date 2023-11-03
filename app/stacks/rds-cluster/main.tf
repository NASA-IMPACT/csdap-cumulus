resource "random_password" "db_password" {
  length  = 50
  upper   = true
  special = false
}

resource "random_password" "db_user_password" {
  length  = 50
  upper   = true
  lower   = true
  number  = true
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
  engine_version           = "11.18"
  parameter_group_family   = "aurora-postgresql11"
  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  provision_user_database  = true
  # ORCA requires us to use a password that contains a special character, but there is
  # some Cumulus constraint that allows only an underscore (in addition to alphanumeric
  # characters), and no other special characters, so we must generate a password that
  # does not contain any special characters, in order to avoid special characters other
  # than an underscore, and then insert an underscore (we chose to at it to the end) to
  # satisfy the ORCA constraint requiring at least one special character.
  rds_user_password   = "${random_password.db_user_password.result}_"
  region              = data.aws_region.current.name
  snapshot_identifier = null
  subnets             = module.vpc.subnets.ids
  tags                = { Deployment = var.prefix }
  vpc_id              = module.vpc.vpc_id
}
