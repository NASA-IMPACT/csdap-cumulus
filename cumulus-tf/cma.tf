resource "null_resource" "fetch_CMA_release" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "curl -L -o cumulus-message-adapter.zip https://github.com/nasa/cumulus-message-adapter/releases/download/${var.cumulus_message_adapter_version}/cumulus-message-adapter.zip"
  }
}

resource "aws_lambda_layer_version" "cma_layer" {
  depends_on = [ null_resource.fetch_CMA_release ]
  source_code_hash = filebase64sha256("${path.module}/cumulus-message-adapter.zip")
  filename = "${path.module}/cumulus-message-adapter.zip"
  layer_name = "${var.prefix}-CMA-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cumulus_message_adapter_version}"
}
