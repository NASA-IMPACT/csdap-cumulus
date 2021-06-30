locals {
  cma_zip_url  = "https://github.com/nasa/cumulus-message-adapter/releases/download/v${var.cumulus_message_adapter_version}/cumulus-message-adapter.zip"
  cma_zip_name = "cumulus-message-adapter-${var.cumulus_message_adapter_version}.zip"
  cma_zip_path = "${path.module}/${local.cma_zip_name}"
}

resource "null_resource" "fetch_CMA_release" {
  triggers = {
    updated_buckets = data.aws_s3_bucket.system_bucket.id
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "curl -L -o ${local.cma_zip_path} ${local.cma_zip_url}"
  }
}

resource "null_resource" "clean_CMA_release" {
  depends_on = [null_resource.fetch_CMA_release, aws_lambda_layer_version.cma_layer]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "rm -f ${local.cma_zip_path}"
  }
}

resource "aws_s3_bucket_object" "cma_release" {
  depends_on = [aws_s3_bucket.var_buckets, null_resource.fetch_CMA_release]
  bucket     = var.system_bucket
  key        = local.cma_zip_name
  source     = local.cma_zip_path
}

resource "aws_lambda_layer_version" "cma_layer" {
  s3_bucket   = var.system_bucket
  s3_key      = aws_s3_bucket_object.cma_release.key
  layer_name  = "${var.prefix}-CMA-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cumulus_message_adapter_version}"
}
