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

## Solution for Bug during Upgrade from v21.2.1 to v21.3.0
## Bug with Log Group already created, uncomment this and set change to the correct environment to load the state locally in order to deploy
## Should only need to do this once per environment for the upgrade
##
## This tells local terraform that the log group has already been created in a previous deployment
#import {
#  to = module.rds_cluster.aws_cloudwatch_log_group.postgresql_logs
#  
#  id = "/aws/rds/cluster/cumulus-kris-sbx7894-rds-serverless/postgresql"
#  #id = "/aws/rds/cluster/cumulus-ops-rds-serverless/postgresql"
#  #id = "/aws/rds/cluster/cumulus-uat-rds-serverless/postgresql"
#  #id = "/aws/rds/cluster/cumulus-prod-rds-serverless/postgresql"
#}

module "rds_cluster" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus-rds.zip"

  cluster_identifier          = "${var.prefix}-rds-serverless"
  db_admin_password           = random_password.db_password.result
  db_admin_username           = "postgres"
  deletion_protection         = true
  engine_version              = "17.4"
  parameter_group_family_v13  = "aurora-postgresql13"
  parameter_group_family_v17  = "aurora-postgresql17"
  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  provision_user_database  = true

  # Keep RDS PostgreSQL CloudWatch logs forever.
  # Cumulus 21.3.x now manages this log group inside the RDS Module.
  # Setting 0 means keep forever
  postgresql_log_retention_days = 0

  min_capacity             = var.min_capacity
  max_capacity             = var.max_capacity
  # ORCA requires us to use a password that contains a special character, but there is
  # some Cumulus constraint that allows only an underscore (in addition to alphanumeric
  # characters), and no other special characters, so we must generate a password that
  # does not contain any special characters, in order to avoid special characters other
  # than an underscore, and then insert an underscore (we chose to at it to the end) to
  # satisfy the ORCA constraint requiring at least one special character.
  rds_user_password   = "${random_password.db_user_password.result}_"
  region              = data.aws_region.current.name
  snapshot_identifier = var.snapshot_identifier
  #snapshot_identifier = null
  subnets             = module.vpc.subnets.ids
  tags                = { Deployment = var.prefix }
  vpc_id              = module.vpc.vpc_id
  # Possible Future v20.x parameter
  #rejectUnauthorized  = false
  
  # When doing a Postgresql Engine Upgrade, Change this value back to false and 
  # only a new parameter group will get deployed that can be used to upgrade your db via AWS Web UI
  enable_upgrade = true

  # This part is to allow Orca v9.0.5 to succeed while doing Cumulus upgrade from 18.2.0 to 18.3.3
  db_parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements,auto_explain"
      apply_method = "pending-reboot"
    },
    {
      name         = "rds.force_ssl"
      value        = 0
      apply_method = "pending-reboot"
    }
  ]
}
