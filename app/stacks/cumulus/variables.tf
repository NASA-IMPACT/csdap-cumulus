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

variable "orca_dlq_subscription_email" {
  type = string
}

variable "private_archive_api_gateway" {
  type    = bool
  default = true
}

variable "rsa_priv_key" {
  description = "The Private Key part of the JWT Token used by TEA Module as part of the TEA s3 credentials access"
  type    = string
  default = ""
}

variable "rsa_pub_key" {
  description = "The Public Key part of the JWT Token used by TEA Module as part of the TEA s3 credentials access"
  type    = string
  default = ""
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

variable "urs_edl_tea_client_id" {
  description = "The Client ID of the Earthdata login (URS) application for TEA s3 credentials access"
  type    = string
  default = ""
}

variable "urs_edl_tea_client_pass" {
  description = "The Password of the Earthdata login (URS) application for TEA s3 credentials access"
  type    = string
  default = ""
}

variable "urs_url" {
  description = "The URL of the Earthdata login (URS) site"
  type        = string
  default     = "https://uat.urs.earthdata.nasa.gov"
}
