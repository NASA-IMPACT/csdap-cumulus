class PatchCumulus18_1_0
  def call(runner)
    mod = runner.mod

    # This is a hack to work around the fact that the Cumulus 18.1.0 S3
    # Replicator module references an undeclared Terraform variable, due to a
    # typo.  This simply patches the module to fix the typo before running
    # `terraform apply`.

    filepath = "#{mod.cache_dir}/.terraform/modules/s3-replicator/main.tf"

    File.write(filepath, File.open(filepath) do |f|
      f.read.gsub(/lambda_memory_size\b/, "lambda_memory_sizes")
    end)

    # Replace all references to deprecated `aws_s3_bucket_object` with `aws_s3_object`
    # This isn't strictly necessary, but it eliminates noisy warnings from Terraform.
    # This can be removed once Cumulus directly addresses the deprecations.

    filepaths = [
      "cumulus/tf-modules/archive/api.tf",
      "cumulus/tf-modules/cumulus/ecs_cluster.tf",
      "cumulus/tf-modules/cumulus/main.tf",
      "cumulus/tf-modules/ingest/message_template.tf",
      "discover_granules_workflow/tf-modules/workflow/main.tf",
      "ingest_and_publish_granule_workflow/tf-modules/workflow/main.tf",
    ]

    filepaths.each do |filepath|
      full_filepath = "#{mod.cache_dir}/.terraform/modules/#{filepath}"
      File.write(full_filepath, File.open(full_filepath) do |f|
        f.read.gsub(/aws_s3_bucket_object/, "aws_s3_object")
      end)
    end
  end
end

before("plan", "apply",
  execute: PatchCumulus18_1_0,
)
