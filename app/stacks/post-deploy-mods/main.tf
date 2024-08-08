# main.tf for post-deploy-mods

# Define the Lambda Function
resource "aws_lambda_function" "pre_filter_DistApiEndpoints" {
  # function_name = "ks-test-pre-filter-DistributionApiEndpoints"
  function_name = "${var.prefix}-pre-filter-DistApiEndpoints"
  filename      = "${path.module}/resources/lambdas/pre-filter-DistributionApiEndpoints/distro/lambda.zip"
  role          = aws_iam_role.lambda_exec_pre_filter_DistApiEndpoints.arn
  handler       = "lambda_function.lambda_handler" #"index.preFilterDistApiEndpoints"
  runtime       = "python3.10" #local.lambda_runtime
  timeout       = 300
  memory_size   = 3008

  source_code_hash = filebase64sha256("${path.module}/resources/lambdas/pre-filter-DistributionApiEndpoints/distro/lambda.zip")

  lifecycle {
    create_before_destroy = true
    prevent_destroy = true
  }
}

# Define the Execution Role and Policy
resource "aws_iam_role" "lambda_exec_pre_filter_DistApiEndpoints" {
  #name = "lambda_exec_role_pre_filter_DistributionApiEndpoints"
  name = "${var.prefix}-lamb_exe_role_pf_DistApiEndpoints"  # Must be 64 chars or less

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  #  lifecycle {
  #    prevent_destroy = true
  #  }
}

# Define an attachment to the aws_iam_role above
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role = aws_iam_role.lambda_exec_pre_filter_DistApiEndpoints.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Define another policy attachment to allow invoking of another lambda
resource "aws_iam_policy" "lambda_invoke_policy" {
  #name        = "lambda_invoke_policy"
  name        = "${var.prefix}-lambda_pf_invoke_policy"
  description = "Policy to allow Lambda functions to invoke other Lambda functions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the Policy, which allows a Lambda to be Invoked, to the Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_invoke_policy_attachment" {
  role        = aws_iam_role.lambda_exec_pre_filter_DistApiEndpoints.name
  policy_arn  = aws_iam_policy.lambda_invoke_policy.arn
}

# Attach an AWS managed Policy for DynamoDB Read Only access
resource "aws_iam_role_policy_attachment" "dynamodb_readonly_policy" {
  role        = aws_iam_role.lambda_exec_pre_filter_DistApiEndpoints.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

# Fetch existing API Gateway
data "aws_api_gateway_rest_api" "distribution_api" {
  name = "${var.prefix}-distribution" # Example "cumulus-uat-distribution"
}

# Fetch the proxy resource (API Gateway "/{proxy+}" prop)
data "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = data.aws_api_gateway_rest_api.distribution_api.id
  path = "/{proxy+}"
}

# No need to update the root resource
# The way this is all set up, we only want to override where the file is downloaded
# That happens only when the proxy is invoked
#
# # If we need to update the root resource than, uncomment this code
# Fetch the root resource (API Gateway "/" prop)
#
#data "aws_api_gateway_resource" "root_resource" {
#  rest_api_id = data.aws_api_gateway_rest_api.distribution_api.id
#  path = "/"
#}
#
#
## Update the integration for the root resource with GET method
#resource "aws_api_gateway_integration" "root_lambda_integration" {
#  rest_api_id = data.aws_api_gateway_rest_api.distribution_api.id
#  resource_id = data.aws_api_gateway_resource.root_resource.id
#  http_method = "GET"
#  integration_http_method = "POST" #"GET"
#  type = "AWS_PROXY"
#  uri = aws_lambda_function.pre_filter_DistApiEndpoints.invoke_arn
#}

# Update the integration for the root resource with GET method
resource "aws_api_gateway_integration" "proxy_lambda_integration" {
  rest_api_id = data.aws_api_gateway_rest_api.distribution_api.id
  resource_id = data.aws_api_gateway_resource.proxy_resource.id
  http_method = "ANY"
  integration_http_method = "POST" #"GET"
  type = "AWS_PROXY"
  uri = aws_lambda_function.pre_filter_DistApiEndpoints.invoke_arn
}

# Ensure the Lambda function as the necessary permissions to be invoked by API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_filter_DistApiEndpoints.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${data.aws_api_gateway_rest_api.distribution_api.execution_arn}/*/*"
}

# Ensure the API Gateway redeploys after the update
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.proxy_lambda_integration]

  rest_api_id = data.aws_api_gateway_rest_api.distribution_api.id
  stage_name = "dev"  # The existing cumulus deployment for this API Gateway Stage is always called dev (in all environments)

  triggers = {
    redeployment = sha1(jsonencode({
      lambda_version = aws_lambda_function.pre_filter_DistApiEndpoints.source_code_hash
      integration_uri = aws_api_gateway_integration.proxy_lambda_integration.uri
    }))
  }
}
