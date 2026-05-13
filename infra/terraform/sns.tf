resource "aws_sns_topic" "notifications" {
  name = local.notifications_topic
}

resource "aws_sns_topic_policy" "notifications" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPollyToPublishTaskUpdates"
        Effect = "Allow"
        Principal = {
          Service = "polly.amazonaws.com"
        }
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
