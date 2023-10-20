data "aws_secretsmanager_secret" "rds_cluster_admin_db_login_secret" {
  arn = "<%= unquoted(output('rds-cluster.admin_db_login_secret_arn')) %>"
}

data "aws_secretsmanager_secret_version" "rds_cluster_admin_db_login_secret_version" {
  secret_id = data.aws_secretsmanager_secret.rds_cluster_admin_db_login_secret.id
}

data "aws_secretsmanager_secret" "rds_cluster_user_credentials_secret" {
  arn = "<%= unquoted(output('rds-cluster.user_credentials_secret_arn')) %>"
}

data "aws_secretsmanager_secret_version" "rds_cluster_user_credentials_secret_version" {
  secret_id = data.aws_secretsmanager_secret.rds_cluster_user_credentials_secret.id
}

module "orca" {
  source = "https://github.com/nasa/cumulus-orca/releases/download/v6.0.3/cumulus-orca-terraform.zip"
  #--------------------------
  # Cumulus variables
  #--------------------------
  # REQUIRED
  buckets                  = var.buckets
  lambda_subnet_ids        = module.vpc.subnets.ids
  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  system_bucket            = var.system_bucket
  vpc_id                   = module.vpc.vpc_id
  workflow_config          = module.cumulus.workflow_config

  # OPTIONAL
  tags = var.tags

  #--------------------------
  # ORCA variables
  #--------------------------
  # REQUIRED
  #
  db_host_endpoint         = local.rds_endpoint
  db_admin_username        = "postgres"
  db_admin_password        = jsondecode(data.aws_secretsmanager_secret_version.rds_cluster_admin_db_login_secret_version.secret_string)["password"]
  db_user_password         = jsondecode(data.aws_secretsmanager_secret_version.rds_cluster_user_credentials_secret_version.secret_string)["password"]
  dlq_subscription_email   = var.orca_dlq_subscription_email
  orca_default_bucket      = var.buckets.orca_default.name
  orca_reports_bucket_name = var.buckets.orca_reports.name
  rds_security_group_id    = local.rds_security_group
  s3_access_key            = data.aws_ssm_parameter.orca_s3_access_key.value
  s3_secret_key            = data.aws_ssm_parameter.orca_s3_secret_key.value

  # OPTIONAL

  # db_admin_username                                    = "postgres"
  # default_multipart_chunksize_mb                       = 250
  # metadata_queue_message_retention_time                = 777600
  # orca_default_recovery_type                           = "Standard"
  orca_default_storage_class                           = "DEEP_ARCHIVE"
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

# Trying to follow: https://nasa.github.io/cumulus-orca/docs/developer/deployment-guide/deployment-with-cumulus#define-the-orca-workflows
# Not understanding exactly where
"MoveGranuleStep": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "bucket": "{$.meta.buckets.internal.name}",
            "buckets": "{$.meta.buckets}",
            "distribution_endpoint": "{$.meta.distribution_endpoint}",
            "collection": "{$.meta.collection}",
            "duplicateHandling": "{$.meta.collection.duplicateHandling}",
            "s3MultipartChunksizeMb": "{$.meta.collection.meta.s3MultipartChunksizeMb}",
            "cumulus_message": {
              "outputs": [
                { "source": "{$}", "destination": "{$.payload}" },
                { "source": "{$.granules}", "destination": "{$.meta.processed_granules}" }
              ]
            }
          }
        }
      },
      "Type": "Task",
      "Resource": "${move_granules_task_arn}",
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],

"CopyToArchive":{
  "Parameters":{
    "cma":{
      "event.$":"$",
      "task_config": {
        "excludedFileExtensions": "{$.meta.collection.meta.orca.excludedFileExtensions}",
        "s3MultipartChunksizeMb": "{$.meta.collection.meta.s3MultipartChunksizeMb}",
        "providerId": "{$.meta.provider.id}",
        "providerName": "{$.meta.provider.name}",
        "executionId": "{$.cumulus_meta.execution_name}",
        "collectionShortname": "{$.meta.collection.name}",
        "collectionVersion": "{$.meta.collection.version}",
        "defaultBucketOverride": "{$.meta.collection.meta.orca.defaultBucketOverride}"
      }
    }
  }
},
  "Type":"Task",
  "Resource":"module.orca.orca_lambda_copy_to_archive_arn",
  "Catch":[
    {
      "ErrorEquals":[
        "States.ALL"
      ],
      "ResultPath":"$.exception",
      "Next":"WorkflowFailed"
    }
  ],
  "Retry": [
    {
      "ErrorEquals": [
        "States.ALL"
      ],
      "IntervalSeconds": 2,
      "MaxAttempts": 3,
      "BackoffRate": 2
    }
  ],
  "Next":"WorkflowSucceeded"
},
