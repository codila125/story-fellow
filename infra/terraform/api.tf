resource "aws_apigatewayv2_api" "story_api" {
  name          = local.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "generate_upload" {
  api_id                 = aws_apigatewayv2_api.story_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.generate_upload.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "create_from_url" {
  api_id                 = aws_apigatewayv2_api.story_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_from_url.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "check_status" {
  api_id                 = aws_apigatewayv2_api.story_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.check_status.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_url" {
  api_id    = aws_apigatewayv2_api.story_api.id
  route_key = "POST /jobs/upload-url"
  target    = "integrations/${aws_apigatewayv2_integration.generate_upload.id}"
}

resource "aws_apigatewayv2_route" "from_url" {
  api_id    = aws_apigatewayv2_api.story_api.id
  route_key = "POST /jobs/from-url"
  target    = "integrations/${aws_apigatewayv2_integration.create_from_url.id}"
}

resource "aws_apigatewayv2_route" "check_status" {
  api_id    = aws_apigatewayv2_api.story_api.id
  route_key = "GET /jobs/{jobId}"
  target    = "integrations/${aws_apigatewayv2_integration.check_status.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.story_api.id
  name        = "prod"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 200
  }
}

resource "aws_lambda_permission" "api_generate_upload" {
  statement_id  = "AllowApiInvokeGenerateUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.story_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_create_from_url" {
  statement_id  = "AllowApiInvokeCreateFromUrl"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_from_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.story_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_check_status" {
  statement_id  = "AllowApiInvokeCheckStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.story_api.execution_arn}/*/*"
}
