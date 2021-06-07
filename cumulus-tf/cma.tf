resource "null_resource" "fetch_CMA_release" {
  triggers = {
    version = var.cumulus_message_adapter_version
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "curl -sL -o cumulus-message-adapter.zip https://github.com/nasa/cumulus-message-adapter/releases/download/v${var.cumulus_message_adapter_version}/cumulus-message-adapter.zip"
  }
}

resource "null_resource" "cleanup_CMA_release" {
  triggers = {
    new_etag = aws_s3_bucket_object.cma_release.etag
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "rm -f cumulus-message-adapter.zip"
  }
}

resource "aws_s3_bucket_object" "cma_release" {
  depends_on = [aws_s3_bucket.var_buckets, null_resource.fetch_CMA_release]
  bucket     = var.system_bucket
  key        = "cumulus-message-adapter-${var.cumulus_message_adapter_version}.zip"
  source     = "${path.module}/cumulus-message-adapter.zip"
}

resource "aws_lambda_layer_version" "cma_layer" {
  s3_bucket   = var.system_bucket
  s3_key      = aws_s3_bucket_object.cma_release.key
  layer_name  = "${var.prefix}-CMA-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cumulus_message_adapter_version}"
}
