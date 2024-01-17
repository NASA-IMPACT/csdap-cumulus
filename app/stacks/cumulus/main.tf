locals {
  protected_bucket_names = [for k, v in var.buckets : v.name if v.type == "protected"]
  public_bucket_names    = [for k, v in var.buckets : v.name if v.type == "public"]

  bucket_map_yaml = templatefile("${path.module}/templates/bucket_map.yaml.tmpl", {
    # This assumes only 1 protected and 1 public bucket
    protected_bucket = local.protected_bucket_names[0],
    public_bucket    = local.public_bucket_names[0],
    base             = "<%= expansion('csdap-cumulus-:ENV') %>",
  })

  cmr_provider = "CSDA"

  dynamo_tables = jsondecode("<%= json_output('data-persistence.dynamo_tables') %>")

  ecs_task_cpu                = 768
  ecs_task_image              = "cumuluss/cumulus-ecs-task:1.9.1"
  ecs_task_memory_reservation = 3277

  elasticsearch_alarms            = jsondecode("<%= json_output('data-persistence.elasticsearch_alarms') %>")
  elasticsearch_domain_arn        = jsondecode("<%= json_output('data-persistence.elasticsearch_domain_arn') %>")
  elasticsearch_hostname          = jsondecode("<%= json_output('data-persistence.elasticsearch_hostname') %>")
  elasticsearch_security_group_id = jsondecode("<%= json_output('data-persistence.elasticsearch_security_group_id') %>")

  lambda_runtime = "nodejs16.x"

  lambda_timeouts = {
    AddMissingFileChecksums            = 900
    DiscoverGranules                   = 900
    MoveGranules                       = 900
    PostToCmr                          = 900
    QueueGranules                      = 900
    SyncGranule                        = 900
    UpdateGranulesCmrMetadataFileLinks = 900
  }

  lambda_memory_sizes = {
    AddMissingFileChecksums            = 3008
    DiscoverGranules                   = 3008
    MoveGranules                       = 3008
    PostToCmr                          = 3008
    QueueGranules                      = 3008
    SyncGranule                        = 3008
    UpdateGranulesCmrMetadataFileLinks = 3008
  }

  rds_security_group         = jsondecode("<%= json_output('rds-cluster.security_group_id') %>")
  rds_user_access_secret_arn = jsondecode("<%= json_output('rds-cluster.user_credentials_secret_arn') %>")
  rds_endpoint               = jsondecode("<%= json_output('rds-cluster.rds_endpoint') %>")

  tags = merge(var.tags, { Deployment = var.prefix })
}

#-------------------------------------------------------------------------------
# DATA (other than SSM Parameters -- see ssm_parameters.tf)
#-------------------------------------------------------------------------------

data "external" "lambda_archive_exploded" {
  program = [
    "/bin/bash",
    "-ic",
    "yarn -s install >/dev/null && yarn -s tf:lambda:archive-exploded"
  ]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = data.external.lambda_archive_exploded.result.dir
  output_path = "${data.external.lambda_archive_exploded.result.dir}/../lambda.zip"
}

data "aws_secretsmanager_secret" "launchpad_pfx" {
  name = "cumulus-launchpad-pfx"
}

# When the Launchpad certificate expires, and a new one is obtained (along with
# a new passphrase), we need to update this secret with the contents of the new
# certificate.  See OPERATING.md for information on updating the Launchpad cert.
data "aws_secretsmanager_secret_version" "launchpad_pfx" {
  secret_id = data.aws_secretsmanager_secret.launchpad_pfx.id
}

#-------------------------------------------------------------------------------
# RESOURCES
#-------------------------------------------------------------------------------

# When the Launchpad certificate secret is updated, we need to update the
# launchpad.pfx file in the system bucket that Cumulus uses to generate tokens
# to authorize publishing to the CMR (via the PostToCmr Lambda function).
resource "aws_s3_object" "launchpad_pfx" {
  bucket         = var.system_bucket
  key            = "${var.prefix}/crypto/launchpad.pfx"
  content_base64 = data.aws_secretsmanager_secret_version.launchpad_pfx.secret_string
}

# <% if !in_sandbox? then %>
resource "null_resource" "put_bucket_logging" {
  for_each = toset(concat(local.protected_bucket_names, local.public_bucket_names))

  triggers = {
    buckets = join(" ", values(var.buckets)[*].name)
  }

  # Since we do not have Terraform configured to manage our buckets, we cannot
  # ask Terraform to configure access logging, so we're calling out to the AWS
  # CLI to configure our "protected" and "public" buckets to write access logs
  # to our "system" (internal) bucket.
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-COMMAND
      aws s3api put-bucket-logging --bucket ${each.key} --bucket-logging-status '
        {
          "LoggingEnabled": {
            "TargetBucket": "${var.system_bucket}",
            "TargetPrefix": "${var.prefix}/ems-distribution/s3-server-access-logs/"
          }
        }
      '
    COMMAND
  }
}
# <% end %>

resource "random_string" "token_secret" {
  length  = 32
  special = true
}

resource "aws_s3_object" "bucket_map_yaml_distribution" {
  bucket  = var.system_bucket
  key     = "${var.prefix}/cumulus_distribution/bucket_map.yaml"
  content = local.bucket_map_yaml
  etag    = md5(local.bucket_map_yaml)
  tags    = local.tags
}

resource "aws_security_group" "egress_only" {
  name   = "${var.prefix}-egress-only"
  vpc_id = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_sqs_queue" "background_job_queue" {
  name                       = "${var.prefix}-backgroundJobQueue"
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 1800
}

resource "aws_cloudwatch_event_rule" "background_job_queue_watcher" {
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "background_job_queue_watcher" {
  rule = aws_cloudwatch_event_rule.background_job_queue_watcher.name
  arn  = module.cumulus.sqs2sfThrottle_lambda_function_arn
  input = jsonencode(
    {
      messageLimit = 300
      queueUrl     = aws_sqs_queue.background_job_queue.id
      timeLimit    = 30
    }
  )
}

resource "aws_lambda_permission" "background_job_queue_watcher" {
  action        = "lambda:InvokeFunction"
  function_name = module.cumulus.sqs2sfThrottle_lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.background_job_queue_watcher.arn
}

resource "aws_lambda_function" "format_provider_paths" {
  function_name = "${var.prefix}-FormatProviderPaths"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.formatProviderPathsHandler"
  runtime       = local.lambda_runtime
  timeout       = 60
  memory_size   = 256

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = local.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }

  environment {
    variables = {
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }
}

resource "aws_lambda_function" "batch_granules" {
  function_name = "${var.prefix}-BatchGranules"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.batchGranulesCMAHandler"
  runtime       = local.lambda_runtime
  timeout       = 900
  memory_size   = 3008

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = var.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }

  environment {
    variables = {
      stackName                   = var.prefix
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }
}

resource "aws_lambda_function" "unbatch_granules" {
  function_name = "${var.prefix}-UnbatchGranules"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.unbatchGranulesCMAHandler"
  runtime       = local.lambda_runtime
  timeout       = 900
  memory_size   = 3008

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = var.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }

  environment {
    variables = {
      stackName                   = var.prefix
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }
}

resource "aws_lambda_function" "prefix_granule_ids" {
  function_name = "${var.prefix}-PrefixGranuleIds"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.prefixGranuleIdsCMAHandler"
  runtime       = local.lambda_runtime
  timeout       = 900
  memory_size   = 3008

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = var.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }

  environment {
    variables = {
      stackName                   = var.prefix
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }
}

resource "aws_lambda_function" "require_cmr_files" {
  function_name = "${var.prefix}-RequireCmrFiles"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.requireCmrFilesCMAHandler"
  runtime       = local.lambda_runtime
  timeout       = 300
  memory_size   = 3008

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = local.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }

  environment {
    variables = {
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }
}

resource "aws_lambda_function" "add_ummg_checksums" {
  function_name = "${var.prefix}-AddUmmgChecksums"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.addUmmgChecksumsCMAHandler"
  runtime       = local.lambda_runtime
  timeout       = 300
  memory_size   = 3008

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = local.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }

  environment {
    variables = {
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }
}

resource "aws_lambda_function" "record_workflow_failure" {
  function_name = "${var.prefix}-RecordWorkflowFailure"
  filename      = data.archive_file.lambda.output_path
  role          = module.cumulus.lambda_processing_role_arn
  handler       = "index.recordWorkflowFailureHandler"
  runtime       = local.lambda_runtime
  timeout       = 60
  memory_size   = 128

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [module.cma.lambda_layer_version_arn]

  tags = local.tags

  dynamic "vpc_config" {
    for_each = length(module.vpc.subnets.ids) == 0 ? [] : [1]
    content {
      subnet_ids         = module.vpc.subnets.ids
      security_group_ids = [aws_security_group.egress_only.id]
    }
  }
}

#-------------------------------------------------------------------------------
# MODULES
#-------------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"
}

module "cma" {
  source = "../../modules/cma"

  prefix      = var.prefix
  bucket      = var.system_bucket
  cma_version = "2.0.3"
}

module "s3-replicator" {
  count                = var.s3_replicator_target_bucket == null ? 0 : 1
  source               = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus-s3-replicator.zip"
  permissions_boundary = local.permissions_boundary_arn
  prefix               = var.prefix
  source_bucket        = var.system_bucket
  source_prefix        = "${var.prefix}/ems-distribution/s3-server-access-logs"
  subnet_ids           = module.vpc.subnets.ids
  target_bucket        = var.s3_replicator_target_bucket
  target_prefix        = var.s3_replicator_target_prefix
  vpc_id               = module.vpc.vpc_id
}

module "cumulus_distribution" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus.zip//tf-modules/cumulus_distribution"

  api_gateway_stage         = "dev"
  api_url                   = var.cumulus_distribution_url
  bucket_map_file           = aws_s3_object.bucket_map_yaml_distribution.id
  bucketname_prefix         = ""
  buckets                   = var.buckets
  cmr_acl_based_credentials = true
  cmr_environment           = var.cmr_environment
  cmr_provider              = local.cmr_provider
  deploy_to_ngap            = true
  lambda_subnet_ids         = module.vpc.subnets.ids

  oauth_client_id       = data.aws_ssm_parameter.csdap_client_id.value
  oauth_client_password = data.aws_ssm_parameter.csdap_client_password.value
  oauth_host_url        = var.csdap_host_url
  oauth_provider        = "cognito"

  permissions_boundary_arn = local.permissions_boundary_arn
  prefix                   = var.prefix
  system_bucket            = var.system_bucket
  tags                     = local.tags
  vpc_id                   = module.vpc.vpc_id
}

module "discover_granules_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus.zip//tf-modules/workflow"

  prefix          = var.prefix
  name            = "DiscoverAndQueueGranules"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = var.system_bucket
  tags            = local.tags

  state_machine_definition = templatefile("${path.module}/templates/discover-granules-workflow.asl.json", {
    ingest_granule_workflow_name : module.ingest_and_publish_granule_workflow.name,
    format_provider_paths_task_arn : aws_lambda_function.format_provider_paths.arn,
    discover_granules_task_arn : module.cumulus.discover_granules_task.task_arn,
    batch_granules_task_arn : aws_lambda_function.batch_granules.arn,
    unbatch_granules_task_arn : aws_lambda_function.unbatch_granules.arn,
    prefix_granule_ids_task_arn : aws_lambda_function.prefix_granule_ids.arn,
    queue_granules_task_arn : module.cumulus.queue_granules_task.task_arn,
    background_job_queue_url : aws_sqs_queue.background_job_queue.id
  })
}

module "ingest_and_publish_granule_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus.zip//tf-modules/workflow"

  prefix          = var.prefix
  name            = "IngestAndPublishGranule"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = var.system_bucket
  tags            = local.tags

  state_machine_definition = templatefile("${path.module}/templates/ingest-and-publish-granule-workflow.asl.json", {
    require_cmr_files_task_arn : aws_lambda_function.require_cmr_files.arn,
    sync_granule_task_arn : module.cumulus.sync_granule_task.task_arn,
    add_ummg_checksums_task_arn : aws_lambda_function.add_ummg_checksums.arn,
    add_missing_file_checksums_task_arn : module.cumulus.add_missing_file_checksums_task.task_arn,
    fake_processing_task_arn : module.cumulus.fake_processing_task.task_arn,
    files_to_granules_task_arn : module.cumulus.files_to_granules_task.task_arn,
    move_granules_task_arn : module.cumulus.move_granules_task.task_arn,
    update_granules_cmr_metadata_file_links_task_arn : module.cumulus.update_granules_cmr_metadata_file_links_task.task_arn,
    copy_to_archive_adapter_task_arn : module.cumulus.orca_copy_to_archive_adapter_task.task_arn,
    post_to_cmr_task_arn : module.cumulus.post_to_cmr_task.task_arn,
    record_workflow_failure_task_arn : aws_lambda_function.record_workflow_failure.arn,
  })
}

module "cumulus" {
  source = "https://github.com/nasa/cumulus/releases/download/<%= cumulus_version %>/terraform-aws-cumulus.zip//tf-modules/cumulus"

  prefix         = var.prefix
  deploy_to_ngap = true

  cumulus_message_adapter_lambda_layer_version_arn = module.cma.lambda_layer_version_arn
  async_operation_image                            = "cumuluss/async-operation:47"

  vpc_id            = module.vpc.vpc_id
  lambda_subnet_ids = module.vpc.subnets.ids
  archive_api_url   = var.archive_api_url

  ecs_cluster_instance_type       = "t3.large"
  ecs_cluster_instance_image_id   = data.aws_ssm_parameter.ecs_image_id.value
  ecs_cluster_instance_subnet_ids = length(var.ecs_cluster_instance_subnet_ids) == 0 ? module.vpc.subnets.ids : var.ecs_cluster_instance_subnet_ids
  ecs_cluster_min_size            = 1
  ecs_cluster_desired_size        = 1
  ecs_cluster_max_size            = 2
  key_name                        = var.key_name

  orca_api_uri                    = module.orca.orca_api_deployment_invoke_url
  orca_lambda_copy_to_archive_arn = module.orca.orca_lambda_copy_to_archive_arn
  orca_sfn_recovery_workflow_arn  = module.orca.orca_sfn_recovery_workflow_arn

  rds_security_group         = local.rds_security_group
  rds_user_access_secret_arn = local.rds_user_access_secret_arn

  # These are no longer used, but are required by the module, so we simply set
  # them to empty strings.
  urs_client_id       = ""
  urs_client_password = ""

  # <% if !in_sandbox? then %>
  metrics_es_host     = var.metrics_es_host
  metrics_es_username = data.aws_ssm_parameter.metrics_es_username.value
  metrics_es_password = data.aws_ssm_parameter.metrics_es_password.value
  # <% end %>

  cmr_client_id      = "<%= expansion('csdap-cumulus-:ENV') %>"
  cmr_environment    = var.cmr_environment
  cmr_oauth_provider = "launchpad"
  cmr_provider       = local.cmr_provider
  # Cumulus bug: since we are using Launchpad for CMR authentication, not EDL,
  # cmr_username and cmr_password should NOT be required, but since they are, we
  # just set them to empty strings.
  cmr_username = ""
  cmr_password = ""

  launchpad_api         = "https://api.launchpad.nasa.gov/icam/api/sm/v1"
  launchpad_certificate = "launchpad.pfx"
  launchpad_passphrase  = data.aws_ssm_parameter.launchpad_passphrase.value

  oauth_provider   = "earthdata"
  oauth_user_group = "N/A"

  saml_entity_id                  = var.saml_entity_id
  saml_assertion_consumer_service = var.saml_assertion_consumer_service
  saml_idp_login                  = var.saml_idp_login
  saml_launchpad_metadata_url     = var.saml_launchpad_metadata_url

  permissions_boundary_arn = local.permissions_boundary_arn

  system_bucket = var.system_bucket
  buckets       = var.buckets

  elasticsearch_alarms            = local.elasticsearch_alarms
  elasticsearch_domain_arn        = local.elasticsearch_domain_arn
  elasticsearch_hostname          = local.elasticsearch_hostname
  elasticsearch_security_group_id = local.elasticsearch_security_group_id

  dynamo_tables = local.dynamo_tables

  es_index_shards = 2

  # Archive API settings
  token_secret                = random_string.token_secret.result
  archive_api_users           = var.api_users
  archive_api_port            = var.archive_api_port
  private_archive_api_gateway = var.private_archive_api_gateway
  api_gateway_stage           = var.api_gateway_stage

  # <% if !in_sandbox? then %>
  log_destination_arn              = data.aws_ssm_parameter.log_destination_arn.value
  report_sns_topic_subscriber_arns = ["arn:aws:iam::${data.aws_ssm_parameter.metrics_aws_account_id.value}:root"]
  # <% end %>
  additional_log_groups_to_elk = var.additional_log_groups_to_elk

  tea_external_api_endpoint                   = var.cumulus_distribution_url
  deploy_cumulus_distribution                 = true
  deploy_distribution_s3_credentials_endpoint = false

  tags = local.tags

  lambda_timeouts     = local.lambda_timeouts
  lambda_memory_sizes = local.lambda_memory_sizes

  throttled_queues = [
    {
      id              = "backgroundJobQueue",
      url             = aws_sqs_queue.background_job_queue.id,
      execution_limit = 500
    }
  ]
}
