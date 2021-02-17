resource "null_resource" "fetch_CMA_release" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "curl -L -o cumulus-message-adapter.zip https://github.com/nasa/cumulus-message-adapter/releases/download/v${var.cumulus_message_adapter_version}/cumulus-message-adapter.zip"
  }
}

resource "aws_s3_bucket_object" "cma_release" {
  depends_on = [null_resource.fetch_CMA_release]
  bucket     = var.system_bucket
  key        = "cumulus-message-adapter-${var.cumulus_message_adapter_version}.zip"
  source     = "${path.module}/cumulus-message-adapter.zip"
}

resource "aws_lambda_layer_version" "cma_layer" {
  s3_bucket  = var.system_bucket
  s3_key     = aws_s3_bucket_object.cma_release.key
  layer_name = "${var.prefix}-CMA-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cumulus_message_adapter_version}"
}
