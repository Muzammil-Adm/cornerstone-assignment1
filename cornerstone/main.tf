provider "aws" {
  region     = "us-east-2"
  access_key = "dummy"
  secret_key = "dummy"
  endpoints {
    lambda       = "http://127.0.0.1:4566"
    s3           = "http://127.0.0.1:4566"
    apigateway   = "http://127.0.0.1:4566"
    apigatewayv2 = "http://127.0.0.1:4566"
    iam          = "http://127.0.0.1:4566"

  }
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  default_tags {
    tags = {
      Environment = "test"
      Name        = "AWS API Gateway Local"
      Service     = "AWS API Gateway Local"
    }
  }
}
resource "aws_api_gateway_rest_api" "example" {
  name = "example-api"
}

resource "aws_api_gateway_resource" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_method" "example" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.example.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "example" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.example.id
  http_method             = aws_api_gateway_method.example.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example.invoke_arn
}

resource "aws_lambda_function" "example" {
  filename         = "example.zip"
  function_name    = "example-lambda"
  role             = aws_iam_role.example.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256("example.zip")
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "example" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
resource "aws_api_gateway_deployment" "example" {
  depends_on  = [aws_api_gateway_integration.example]
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = "dev"
}
output "base_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}
