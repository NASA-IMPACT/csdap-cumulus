#-------------------------------------------------------------------------------
# REQUIRED
#-------------------------------------------------------------------------------

variable "buckets" {
  type = map(object({ name = string, type = string }))
}

variable "cmr_environment" {
  type = string
  validation {
    condition     = length(regexall("^(?:UAT|OPS)$", var.cmr_environment)) == 1
    error_message = "ERROR: Valid types are \"UAT\" and \"OPS\"!"
  }
}

variable "system_bucket" {
  type = string
}

#-------------------------------------------------------------------------------
# OPTIONAL
#-------------------------------------------------------------------------------

variable "additional_log_groups_to_elk" {
  type    = map(string)
  default = {}
}

variable "api_gateway_stage" {
  type        = string
  default     = "dev"
  description = "The archive API Gateway stage to create"
}

variable "api_users" {
  type    = list(string)
  default = []
}

variable "archive_api_port" {
  type    = number
  default = 8000
}

variable "archive_api_url" {
  description = "Cloudfront endpoint for Cumulus"
  type        = string
  default     = null
}

variable "csdap_host_url" {
  type    = string
  default = "N/A"
}

variable "cumulus_distribution_url" {
  type    = string
  default = null
}

variable "ecs_cluster_instance_subnet_ids" {
  type    = list(string)
  default = []
}

variable "ems_datasource" {
  type        = string
  description = "the data source of EMS reports"
  default     = "UAT"
}

variable "ems_deploy" {
  description = "If true, deploys the EMS reporting module"
  type        = bool
  default     = true
}

variable "ems_host" {
  type        = string
  description = "EMS host"
  default     = "change-ems-host"
}

variable "ems_path" {
  type        = string
  description = "EMS host directory path for reports"
  default     = "/"
}

variable "ems_port" {
  type        = number
  description = "EMS host port"
  default     = 22
}

variable "ems_private_key" {
  type        = string
  description = "the private key file used for sending reports to EMS"
  default     = "ems-private.pem"
}

variable "ems_provider" {
  type        = string
  description = "the provider used for sending reports to EMS"
  default     = null
}

variable "ems_retention_in_days" {
  type        = number
  description = "the retention in days for reports and s3 server access logs"
  default     = 30
}

variable "ems_submit_report" {
  type        = bool
  description = "toggle whether the reports will be sent to EMS"
  default     = false
}

variable "ems_username" {
  type        = string
  description = "the username used for sending reports to EMS"
  default     = null
}

variable "key_name" {
  type    = string
  default = null
}

variable "log_api_gateway_to_cloudwatch" {
  type        = bool
  default     = false
  description = "Enable logging of API Gateway activity to CloudWatch."
}

variable "log_destination_arn" {
  type        = string
  default     = null
  description = "Remote kinesis/destination arn for delivering logs. Requires log_api_gateway_to_cloudwatch set to true."
}

variable "metrics_es_host" {
  type    = string
  default = null
}

variable "metrics_es_password" {
  type    = string
  default = null
}

variable "metrics_es_username" {
  type    = string
  default = null
}

variable "private_archive_api_gateway" {
  type    = bool
  default = true
}

variable "s3_replicator_target_bucket" {
  type    = string
  default = null
}

variable "s3_replicator_target_prefix" {
  type    = string
  default = null
}

variable "saml_assertion_consumer_service" {
  type    = string
  default = "N/A"
}

variable "saml_entity_id" {
  type    = string
  default = "N/A"
}

variable "saml_idp_login" {
  type    = string
  default = "N/A"
}

variable "saml_launchpad_metadata_url" {
  type    = string
  default = "N/A"
}

variable "tags" {
  description = "Tags to be applied to Cumulus resources that support tags"
  type        = map(string)
  default     = {}
}

# ORCA Variables
#variable "db_admin_password" {
#
#}

#variable "db_user_password" {
#
#}
variable "dlq_subscription_email" {
  default = "pic8690@gmail.com"
}

# TODO
# https://nasa.github.io/cumulus-orca/docs/developer/deployment-guide/deployment-s3-bucket/
variable "orca_default_bucket" {
  default = "csda-cumulus-cba-uat-orca-archive" # TODO - Go to Disaster Recovery Account
}
variable "orca_reports_bucket_name" {
  default = "csda-cumulus-cba-uat-orca-reports"
}

# TODO - Remove these from here all together during the PR
# These have been moved to ssm_parameters.tf
# Leaving these here while this task is still a Work in Progress
#
#variable "s3_access_key" {
#  default = "Axxx"
#}
#variable "s3_secret_key" {
#  default = "Axxx"
#}




