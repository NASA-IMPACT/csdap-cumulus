locals {
  cma_zip_url  = "https://github.com/nasa/cumulus-message-adapter/releases/download/v${var.cma_version}/cumulus-message-adapter.zip"
  cma_zip_name = "cumulus-message-adapter-${var.cma_version}.zip"
  cma_zip_path = "${path.module}/${local.cma_zip_name}"
}

resource "null_resource" "download_cma_zip_file" {
  triggers = {
    bucket  = var.bucket
    version = var.cma_version
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "curl -sSL -o ${local.cma_zip_path} ${local.cma_zip_url}"
  }
}

resource "aws_s3_bucket_object" "cma_zip_file" {
  depends_on = [null_resource.download_cma_zip_file]
  bucket     = var.bucket
  key        = local.cma_zip_name
  source     = local.cma_zip_path

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "rm -f ${local.cma_zip_path}"
  }
}

resource "aws_lambda_layer_version" "cma" {
  s3_bucket   = var.bucket
  s3_key      = aws_s3_bucket_object.cma_zip_file.key
  layer_name  = "${var.prefix}-cumulus-message-adapter"
  description = "Lambda layer for Cumulus Message Adapter ${var.cma_version}"
}
