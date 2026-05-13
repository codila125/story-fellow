resource "aws_lambda_permission" "allow_s3_to_start" {
  statement_id  = "AllowS3InvokeStartStorycast"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_storycast.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn
}

resource "aws_s3_bucket_notification" "input_object_created" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.start_storycast.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_start]
}

resource "aws_cloudwatch_event_rule" "polly_task_state_change" {
  name        = "${local.name_prefix}-polly-task-state-change"
  description = "Capture Polly synthesis task state change events"

  event_pattern = jsonencode({
    source = ["aws.polly"]
    "detail-type" = ["Polly Synthesis Task State Change"]
  })
}

resource "aws_cloudwatch_event_target" "polly_updater" {
  rule      = aws_cloudwatch_event_rule.polly_task_state_change.name
  target_id = "polly-task-status-updater"
  arn       = aws_lambda_function.polly_updater.arn
}

resource "aws_lambda_permission" "allow_eventbridge_to_updater" {
  statement_id  = "AllowEventBridgeInvokePollyUpdater"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.polly_updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.polly_task_state_change.arn
}
