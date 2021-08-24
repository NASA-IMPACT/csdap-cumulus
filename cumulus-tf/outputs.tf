output "archive_api_uri" {
  value = module.cumulus.archive_api_uri
}

output "archive_api_redirect_uri" {
  value = module.cumulus.archive_api_redirect_uri
}

output "s3_credentials_redirect_uri" {
  value = module.cumulus.s3_credentials_redirect_uri
}

output "cumulus_distribution_api_uri" {
  value = module.cumulus_distribution.api_uri
}

output "cumulus_distribution_api_redirect_uri" {
  value = module.cumulus_distribution.api_redirect_uri
}

# Cumulus Distribution outputs
output "cumulus_distribution_api_uri" {
   value = module.cumulus_distribution.api_uri
}

output "cumulus_distribution_api_redirect_uri" {
  value = module.cumulus_distribution.api_redirect_uri
}

# Workflow reporting SQS queue and SNS topics

output "stepfunction_event_reporter_queue_url" {
  value = module.cumulus.stepfunction_event_reporter_queue_url
}

output "report_executions_sns_topic_arn" {
  value = module.cumulus.report_executions_sns_topic_arn
}

output "report_granules_sns_topic_arn" {
  value = module.cumulus.report_granules_sns_topic_arn
}

output "report_pdrs_sns_topic_arn" {
  value = module.cumulus.report_pdrs_sns_topic_arn
}
