resource "aws_athena_database" "cumulus" {
  name   = lower(replace("${var.prefix}_failures", "-", "_"))
  bucket = var.system_bucket
}

resource "aws_glue_catalog_table" "ingest_and_publish_workflow_failures" {
  database_name = aws_athena_database.cumulus.name
  name          = "ingest_and_publish_workflow_failures"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL       = "TRUE"
    classification = "json"
  }

  storage_descriptor {
    location      = "s3://${var.system_bucket}/failures/${module.ingest_and_publish_granule_workflow.name}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name    = "stack"
      type    = "string"
      comment = "Name of the stack in which the failed workflow execution ran (e.g., prod, uat, dev1, dev2, etc.)"
    }
    columns {
      name    = "cumulus_version"
      type    = "string"
      comment = "Version of Cumulus deployed during workflow execution"
    }
    columns {
      name    = "state_machine_arn"
      type    = "string"
      comment = "ARN of the workflow (step function)"
    }
    columns {
      name    = "state_machine_name"
      type    = "string"
      comment = "Name of the workflow (step function)"
    }
    columns {
      name    = "execution_name"
      type    = "string"
      comment = "UUID of the workflow execution that failed"
    }
    columns {
      name    = "start_time"
      type    = "timestamp"
      comment = "UTC time (in seconds, floating point) when the workflow execution started"
    }
    columns {
      name    = "parent_execution_arn"
      type    = "string"
      comment = "ARN of the parent workflow execution that triggered this failed workflow execution"
    }
    columns {
      name    = "collection_name"
      type    = "string"
      comment = "Name of the collection that was being processed"
    }
    columns {
      name    = "collection_version"
      type    = "string"
      comment = "Version of the collection that was being processed"
    }
    columns {
      name    = "provider_bucket"
      type    = "string"
      comment = "Name of the provider (source) bucket from which granules were being ingested"
    }
    columns {
      name    = "granule_ids"
      type    = "array<string>"
      comment = "IDs of the granules that were being processed (controlled by the collection's meta.preferredQueueBatchSize setting [default: 1])"
    }
    columns {
      name    = "error_type"
      type    = "string"
      comment = "Type of error that caused the workflow to fail"
    }
    columns {
      name    = "error_message"
      type    = "string"
      comment = "Description of the error that caused the workflow to fail"
    }
    columns {
      name    = "error_trace"
      type    = "array<string>"
      comment = "Stack trace of the error that caused the workflow to fail"
    }
  }
}

#-------------------------------------------------------------------------------
# Queries across all parent executions.
#-------------------------------------------------------------------------------

resource "aws_athena_named_query" "ingestion_failure_counts_by_error_type" {
  name        = "ingestion_failure_counts_by_error_type"
  database    = aws_athena_database.cumulus.name
  description = "Failure counts by error type across all ingestions"
  query       = <<-QUERY
    SELECT error_type, count(*) as count
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    GROUP BY error_type
    ORDER BY count DESC;
  QUERY
}

resource "aws_athena_named_query" "ingestion_failure_counts_by_error_type_by_parent" {
  name        = "ingestion_failure_counts_by_error_type_by_parent"
  database    = aws_athena_database.cumulus.name
  description = "Failure counts by ingestion and error type across all ingestions"
  query       = <<-QUERY
    SELECT parent_execution_arn, error_type, count(*) as count
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    GROUP BY parent_execution_arn, error_type
    ORDER BY parent_execution_arn, count DESC;
  QUERY
}

resource "aws_athena_named_query" "ingestion_failures_for_error_type" {
  name        = "ingestion_failures_for_error_type"
  database    = aws_athena_database.cumulus.name
  description = "Failures for given error type across all ingestions"
  query       = <<-QUERY
    SELECT error_type, error_message, error_trace
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    WHERE error_type = ?;
  QUERY
}

#-------------------------------------------------------------------------------
# Queries for latest parent execution ARN, which is the most recently executed
# workflow execution, regardless of current status (i.e., it may still be
# running).
#-------------------------------------------------------------------------------

resource "aws_athena_named_query" "ingestion_failure_counts_by_error_type_for_latest" {
  name        = "ingestion_failure_counts_by_error_type_for_latest"
  database    = aws_athena_database.cumulus.name
  description = "Failure counts by error type for most recent ingestion"
  query       = <<-QUERY
    SELECT error_type, count(*) as count
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    WHERE parent_execution_arn = (
        SELECT parent_execution_arn
        FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
        ORDER BY start_time DESC
        LIMIT 1
      )
    GROUP BY error_type
    ORDER BY count DESC;
  QUERY
}

resource "aws_athena_named_query" "ingestion_failures_for_error_type_for_latest" {
  name        = "ingestion_failures_for_error_type_for_latest"
  database    = aws_athena_database.cumulus.name
  description = "Failures for given error type for most recent ingestion"
  query       = <<-QUERY
    SELECT parent_execution_arn, error_type, error_message, error_trace
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    WHERE parent_execution_arn = (
        SELECT parent_execution_arn
        FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
        ORDER BY start_time DESC
        LIMIT 1
      )
      AND error_type = ?;
  QUERY
}

#-------------------------------------------------------------------------------
# Parameterized queries for a given parent execution ARN
#-------------------------------------------------------------------------------

resource "aws_athena_named_query" "ingestion_failure_counts_by_error_type_for_parent" {
  name        = "ingestion_failure_counts_by_error_type_for_parent"
  database    = aws_athena_database.cumulus.name
  description = "Failure counts by error type for given parent execution"
  query       = <<-QUERY
    SELECT error_type, count(*) as count
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    WHERE parent_execution_arn = ?
    GROUP BY error_type
    ORDER BY count DESC;
  QUERY
}

resource "aws_athena_named_query" "ingestion_failures_for_error_type_for_parent" {
  name        = "ingestion_failures_for_error_type_for_parent"
  database    = aws_athena_database.cumulus.name
  description = "Failures for given parent execution and error type"
  query       = <<-QUERY
    SELECT error_type, error_message, error_trace
    FROM ${aws_glue_catalog_table.ingest_and_publish_workflow_failures.name}
    WHERE parent_execution_arn = ? AND error_type = ?;
  QUERY
}
