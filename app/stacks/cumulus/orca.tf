## ORCA Module
## =============================================================================
resource "random_password" "db_password" {
  length  = 50
  upper   = true
  special = false
}
module "orca" {
  source = "https://github.com/nasa/cumulus-orca/releases/download/v6.0.2/cumulus-orca-terraform.zip"
  ## --------------------------
  ## Cumulus Variables
  ## --------------------------
  ## REQUIRED
  buckets                  = var.buckets
  lambda_subnet_ids        = var.lambda_subnet_ids
  permissions_boundary_arn = var.permissions_boundary_arn
  prefix                   = var.prefix
  system_bucket            = var.system_bucket
  vpc_id                   = module.vpc.vpc_id
  workflow_config          = module.cumulus.workflow_config

  ## OPTIONAL
  tags        = var.tags

  ## --------------------------
  ## ORCA Variables
  ## --------------------------
  ## REQUIRED
  db_admin_password        = random_password.db_password.result
  db_host_endpoint         = local.rds_endpoint
  db_user_password         = random_password.db_password.result
  dlq_subscription_email   = var.dlq_subscription_email
  orca_default_bucket      = var.orca_default_bucket
  orca_reports_bucket_name = var.orca_reports_bucket_name
  rds_security_group_id    = var.rds_security_group_id

  ## OPTIONAL
  # db_admin_username                                    = "postgres"
  # default_multipart_chunksize_mb                       = 250
  # metadata_queue_message_retention_time                = 777600
  # orca_default_recovery_type                           = "Standard"
  # orca_default_storage_class                           = "GLACIER"
  # orca_delete_old_reconcile_jobs_frequency_cron        = "cron(0 0 ? * SUN *)"
  # orca_ingest_lambda_memory_size                       = 2240
  # orca_ingest_lambda_timeout                           = 600
  # orca_internal_reconciliation_expiration_days         = 30
  # orca_reconciliation_lambda_memory_size               = 128
  # orca_reconciliation_lambda_timeout                   = 720
  # orca_recovery_buckets                                = []
  # orca_recovery_complete_filter_prefix                 = ""
  # orca_recovery_expiration_days                        = 5
  # orca_recovery_lambda_memory_size                     = 128
  # orca_recovery_lambda_timeout                         = 720
  # orca_recovery_retry_limit                            = 3
  # orca_recovery_retry_interval                         = 1
  # orca_recovery_retry_backoff                          = 2
  # s3_inventory_queue_message_retention_time_seconds    = 432000
  # s3_report_frequency                                  = "Daily"
  # sqs_delay_time_seconds                               = 0
  # sqs_maximum_message_size                             = 262144
  # staged_recovery_queue_message_retention_time_seconds = 432000
  # status_update_queue_message_retention_time_seconds   = 777600

}
