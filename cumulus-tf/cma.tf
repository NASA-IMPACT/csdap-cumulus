resource "null_resource" "CMA_release" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "curl -L -o cumulus-message-adapter.zip https://github.com/nasa/cumulus-message-adapter/releases/download/${var.cma_version}/cumulus-message-adapter.zip"
  }
}

resource "aws_lambda_layer_version" "cma_layer" {
  source_code_hash = filebase64sha256("${path.module}/cumulus-message-adapter.zip")
  filename = "${path.module}/cumulus-message-adapter.zip"
  layer_name = "${local.prefix}-CMA-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cma_version}"
}
