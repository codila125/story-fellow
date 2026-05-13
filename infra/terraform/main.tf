data "aws_caller_identity" "current" {}

locals {
  name_prefix             = "${var.project_name}-${var.environment}"
  input_bucket_name       = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-input"
  output_bucket_name      = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-output"
  website_bucket_name     = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-web"
  jobs_table_name         = "${local.name_prefix}-jobs"
  notifications_topic     = "${local.name_prefix}-notifications"
  api_name                = "${local.name_prefix}-api"
  upload_function_name    = "${local.name_prefix}-generate-upload-url"
  from_url_function_name  = "${local.name_prefix}-create-job-from-url"
  start_function_name     = "${local.name_prefix}-start-narration-job"
  status_function_name    = "${local.name_prefix}-check-narration-status"
  updater_function_name   = "${local.name_prefix}-polly-task-status-updater"
  lambda_log_group_prefix = "/aws/lambda"
}

data "archive_file" "generate_upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../generate-upload-url"
  output_path = "${path.module}/../../.generate-upload-url.zip"
}

data "archive_file" "create_from_url_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../create-job-from-url"
  output_path = "${path.module}/../../.create-job-from-url.zip"
}

data "archive_file" "start_storycast_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../start-storycast"
  output_path = "${path.module}/../../.start-storycast.zip"
}

data "archive_file" "check_status_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../check-storycast-status"
  output_path = "${path.module}/../../.check-storycast-status.zip"
}

data "archive_file" "polly_updater_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../polly-task-status-updater"
  output_path = "${path.module}/../../.polly-task-status-updater.zip"
}
