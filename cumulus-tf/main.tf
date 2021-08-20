terraform {
  required_version = "0.13.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

locals {
  tags = merge(var.tags, { Deployment = var.prefix })

  elasticsearch_alarms            = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_alarms", [])
  elasticsearch_domain_arn        = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_domain_arn", null)
  elasticsearch_hostname          = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_hostname", null)
  elasticsearch_security_group_id = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_security_group_id", "")

  ngap_subnet_ids            = data.aws_subnet_ids.ngap_subnets.ids
  permissions_boundary_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary_name}"
  rds_security_group         = lookup(data.terraform_remote_state.data_persistence.outputs, "rds_security_group_id", "")
  rds_user_access_secret_arn = lookup(data.terraform_remote_state.data_persistence.outputs, "rds_user_access_secret_arn", "")
}

data "aws_s3_bucket" "system_bucket" {
  bucket = var.system_bucket
}

module "cumulus" {
  source = "https://github.com/nasa/cumulus/releases/download/v9.3.0/terraform-aws-cumulus.zip//tf-modules/cumulus"

  depends_on = [data.aws_s3_bucket.system_bucket]

  # DO NOT change this value unless deploying outside of NGAP
  deploy_to_ngap = true

  cumulus_message_adapter_lambda_layer_version_arn = aws_lambda_layer_version.cma_layer.arn

  prefix = var.prefix

  vpc_id            = data.aws_vpc.ngap_vpc.id
  lambda_subnet_ids = local.ngap_subnet_ids
  archive_api_url   = var.archive_api_url

  ecs_cluster_instance_image_id   = data.aws_ssm_parameter.ecs_image_id.value
  ecs_cluster_instance_subnet_ids = length(var.ecs_cluster_instance_subnet_ids) == 0 ? local.ngap_subnet_ids : var.ecs_cluster_instance_subnet_ids
  ecs_cluster_min_size            = 1
  ecs_cluster_desired_size        = 1
  ecs_cluster_max_size            = 2
  key_name                        = var.key_name

  rds_security_group         = local.rds_security_group
  rds_user_access_secret_arn = local.rds_user_access_secret_arn
  rds_connection_heartbeat   = true

  urs_url             = var.urs_url
  urs_client_id       = var.urs_client_id
  urs_client_password = var.urs_client_password

  metrics_es_host     = var.metrics_es_host
  metrics_es_password = var.metrics_es_password
  metrics_es_username = var.metrics_es_username

  cmr_client_id   = var.cmr_client_id
  cmr_environment = var.cmr_environment
  cmr_username    = var.cmr_username
  cmr_password    = var.cmr_password
  cmr_provider    = var.cmr_provider

  cmr_oauth_provider = var.cmr_oauth_provider

  launchpad_api         = var.launchpad_api
  launchpad_certificate = var.launchpad_certificate
  launchpad_passphrase  = var.launchpad_passphrase

  oauth_provider   = var.oauth_provider
  oauth_user_group = var.oauth_user_group

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

  dynamo_tables = data.terraform_remote_state.data_persistence.outputs.dynamo_tables

  es_index_shards = 2

  # Archive API settings
  token_secret                = random_string.token_secret.result
  archive_api_users           = var.api_users
  archive_api_port            = var.archive_api_port
  private_archive_api_gateway = var.private_archive_api_gateway
  api_gateway_stage           = var.api_gateway_stage

  log_destination_arn          = var.log_destination_arn
  additional_log_groups_to_elk = var.additional_log_groups_to_elk

  tea_external_api_endpoint                   = var.cumulus_distribution_url
  deploy_cumulus_distribution                 = true
  deploy_distribution_s3_credentials_endpoint = false

  tags = local.tags
}
