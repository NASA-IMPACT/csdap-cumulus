module "discover_granules_workflow" {
  source     = "https://github.com/nasa/cumulus/releases/download/v9.1.0/terraform-aws-cumulus.zip//tf-modules/workflow"
  depends_on = [aws_s3_bucket.var_buckets]

  prefix          = var.prefix
  name            = "DiscoverAndPublishGranules"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = var.system_bucket
  tags            = local.tags

  state_machine_definition = templatefile(
    "discover-granules-workflow.asl.json",
    {
      ingest_granule_workflow_name : module.ingest_and_publish_granule_workflow.name,
      discover_granules_task_arn : module.cumulus.discover_granules_task.task_arn,
      queue_granules_task_arn : module.cumulus.queue_granules_task.task_arn,
      start_sf_queue_url : module.cumulus.start_sf_queue_url
    }
  )
}