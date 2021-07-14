module "ingest_and_publish_granule_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/v9.1.0/terraform-aws-cumulus.zip//tf-modules/workflow"

  prefix          = var.prefix
  name            = "IngestAndPublishGranule"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = data.aws_s3_bucket.system_bucket.id
  tags            = local.tags

  state_machine_definition = templatefile(
    "ingest-and-publish-granule-workflow.asl.json",
    {
      sync_granule_task_arn : module.cumulus.sync_granule_task.task_arn,
      add_missing_file_checksums_task_arn : module.cumulus.add_missing_file_checksums_task.task_arn,
      fake_processing_task_arn : module.cumulus.fake_processing_task.task_arn,
      files_to_granules_task_arn : module.cumulus.files_to_granules_task.task_arn,
      move_granules_task_arn : module.cumulus.move_granules_task.task_arn,
      update_granules_cmr_metadata_file_links_task_arn : module.cumulus.update_granules_cmr_metadata_file_links_task.task_arn,
      post_to_cmr_task_arn : module.cumulus.post_to_cmr_task.task_arn
    }
  )
}
