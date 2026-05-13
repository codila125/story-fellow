data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "generate_upload" {
  name               = "${local.upload_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "create_from_url" {
  name               = "${local.from_url_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "start_storycast" {
  name               = "${local.start_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "check_status" {
  name               = "${local.status_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "polly_updater" {
  name               = "${local.updater_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "generate_upload" {
  statement {
    sid    = "WriteInputPrefix"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.input.arn}/input/*"]
  }

  statement {
    sid    = "WriteJobs"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.jobs.arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.generate_upload.arn}:*"]
  }
}

resource "aws_iam_role_policy" "generate_upload" {
  name   = "${local.upload_function_name}-inline"
  role   = aws_iam_role.generate_upload.id
  policy = data.aws_iam_policy_document.generate_upload.json
}

data "aws_iam_policy_document" "create_from_url" {
  statement {
    sid    = "WriteInputPrefix"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.input.arn}/input/*"]
  }

  statement {
    sid    = "WriteJobs"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.jobs.arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.create_from_url.arn}:*"]
  }
}

resource "aws_iam_role_policy" "create_from_url" {
  name   = "${local.from_url_function_name}-inline"
  role   = aws_iam_role.create_from_url.id
  policy = data.aws_iam_policy_document.create_from_url.json
}

data "aws_iam_policy_document" "start_storycast" {
  statement {
    sid    = "ReadInputPrefix"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${aws_s3_bucket.input.arn}/input/*"]
  }

  statement {
    sid    = "PollyStartSynthesis"
    effect = "Allow"
    actions = [
      "polly:StartSpeechSynthesisTask"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadWriteJobs"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem"
    ]
    resources = [aws_dynamodb_table.jobs.arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.start_storycast.arn}:*"]
  }
}

resource "aws_iam_role_policy" "start_storycast" {
  name   = "${local.start_function_name}-inline"
  role   = aws_iam_role.start_storycast.id
  policy = data.aws_iam_policy_document.start_storycast.json
}

data "aws_iam_policy_document" "check_status" {
  statement {
    sid    = "ReadJobs"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem"
    ]
    resources = [aws_dynamodb_table.jobs.arn]
  }

  statement {
    sid    = "ReadOutputObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${aws_s3_bucket.output.arn}/*"]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.check_status.arn}:*"]
  }
}

resource "aws_iam_role_policy" "check_status" {
  name   = "${local.status_function_name}-inline"
  role   = aws_iam_role.check_status.id
  policy = data.aws_iam_policy_document.check_status.json
}

data "aws_iam_policy_document" "polly_updater" {
  statement {
    sid    = "UpdateJobs"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.jobs.arn]
  }

  statement {
    sid    = "PublishNotifications"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.notifications.arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.polly_updater.arn}:*"]
  }
}

resource "aws_iam_role_policy" "polly_updater" {
  name   = "${local.updater_function_name}-inline"
  role   = aws_iam_role.polly_updater.id
  policy = data.aws_iam_policy_document.polly_updater.json
}
