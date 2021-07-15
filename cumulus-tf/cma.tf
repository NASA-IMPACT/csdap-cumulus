locals {
  cma_zip_url  = "https://github.com/nasa/cumulus-message-adapter/releases/download/v${var.cumulus_message_adapter_version}/cumulus-message-adapter.zip"
  cma_zip_name = "cumulus-message-adapter-${var.cumulus_message_adapter_version}.zip"
  cma_zip_path = "${path.module}/${local.cma_zip_name}"
}

resource "null_resource" "fetch_cma_release" {
  triggers = {
    system_bucket_id = data.aws_s3_bucket.system_bucket.id
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "curl -sSL -o ${local.cma_zip_path} ${local.cma_zip_url}"
  }
}

resource "null_resource" "clean_cma_release" {
  triggers = {
    exists = fileexists(aws_s3_bucket_object.cma_release.source)
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "rm -f ${aws_s3_bucket_object.cma_release.source}"
  }
}

resource "aws_s3_bucket_object" "cma_release" {
  depends_on = [null_resource.fetch_cma_release]
  bucket     = data.aws_s3_bucket.system_bucket.id
  key        = local.cma_zip_name
  source     = local.cma_zip_path
}

resource "aws_lambda_layer_version" "cma_layer" {
  s3_bucket   = data.aws_s3_bucket.system_bucket.id
  s3_key      = aws_s3_bucket_object.cma_release.key
  layer_name  = "${var.prefix}-cma-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cumulus_message_adapter_version}"
}
