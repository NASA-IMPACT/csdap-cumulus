output "cma_zip_file_id" {
  value = aws_s3_object.cma_zip_file.id
}

output "lambda_layer_version_arn" {
  value = aws_lambda_layer_version.cma.arn
}
