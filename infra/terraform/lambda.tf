resource "aws_cloudwatch_log_group" "generate_upload" {
  name              = "${local.lambda_log_group_prefix}/${local.upload_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "create_from_url" {
  name              = "${local.lambda_log_group_prefix}/${local.from_url_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "start_storycast" {
  name              = "${local.lambda_log_group_prefix}/${local.start_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "check_status" {
  name              = "${local.lambda_log_group_prefix}/${local.status_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "polly_updater" {
  name              = "${local.lambda_log_group_prefix}/${local.updater_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "generate_upload" {
  function_name = local.upload_function_name
  role          = aws_iam_role.generate_upload.arn
  runtime       = var.python_runtime
  handler       = "app.handler"
  timeout       = var.lambda_timeout_seconds
  memory_size   = var.lambda_memory_mb

  filename         = data.archive_file.generate_upload_zip.output_path
  source_code_hash = data.archive_file.generate_upload_zip.output_base64sha256

  environment {
    variables = {
      JOB_TABLE_NAME    = aws_dynamodb_table.jobs.name
      INPUT_BUCKET_NAME = aws_s3_bucket.input.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy.generate_upload,
    aws_cloudwatch_log_group.generate_upload
  ]
}

resource "aws_lambda_function" "create_from_url" {
  function_name = local.from_url_function_name
  role          = aws_iam_role.create_from_url.arn
  runtime       = var.python_runtime
  handler       = "app.handler"
  timeout       = 60
  memory_size   = var.lambda_memory_mb

  filename         = data.archive_file.create_from_url_zip.output_path
  source_code_hash = data.archive_file.create_from_url_zip.output_base64sha256

  environment {
    variables = {
      JOB_TABLE_NAME    = aws_dynamodb_table.jobs.name
      INPUT_BUCKET_NAME = aws_s3_bucket.input.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy.create_from_url,
    aws_cloudwatch_log_group.create_from_url
  ]
}

resource "aws_lambda_function" "start_storycast" {
  function_name = local.start_function_name
  role          = aws_iam_role.start_storycast.arn
  runtime       = var.python_runtime
  handler       = "app.handler"
  timeout       = 120
  memory_size   = var.lambda_memory_mb

  filename         = data.archive_file.start_storycast_zip.output_path
  source_code_hash = data.archive_file.start_storycast_zip.output_base64sha256

  environment {
    variables = {
      JOB_TABLE_NAME      = aws_dynamodb_table.jobs.name
      OUTPUT_BUCKET_NAME  = aws_s3_bucket.output.bucket
      POLLY_OUTPUT_PREFIX = var.polly_output_prefix
      SNS_TOPIC_ARN       = aws_sns_topic.notifications.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.start_storycast,
    aws_cloudwatch_log_group.start_storycast
  ]
}

resource "aws_lambda_function" "check_status" {
  function_name = local.status_function_name
  role          = aws_iam_role.check_status.arn
  runtime       = var.python_runtime
  handler       = "app.handler"
  timeout       = var.lambda_timeout_seconds
  memory_size   = var.lambda_memory_mb

  filename         = data.archive_file.check_status_zip.output_path
  source_code_hash = data.archive_file.check_status_zip.output_base64sha256

  environment {
    variables = {
      JOB_TABLE_NAME     = aws_dynamodb_table.jobs.name
      OUTPUT_BUCKET_NAME = aws_s3_bucket.output.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy.check_status,
    aws_cloudwatch_log_group.check_status
  ]
}

resource "aws_lambda_function" "polly_updater" {
  function_name = local.updater_function_name
  role          = aws_iam_role.polly_updater.arn
  runtime       = var.python_runtime
  handler       = "app.handler"
  timeout       = var.lambda_timeout_seconds
  memory_size   = var.lambda_memory_mb

  filename         = data.archive_file.polly_updater_zip.output_path
  source_code_hash = data.archive_file.polly_updater_zip.output_base64sha256

  environment {
    variables = {
      JOB_TABLE_NAME = aws_dynamodb_table.jobs.name
      SNS_TOPIC_ARN  = aws_sns_topic.notifications.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.polly_updater,
    aws_cloudwatch_log_group.polly_updater
  ]
}
