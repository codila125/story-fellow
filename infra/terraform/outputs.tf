output "api_base_url" {
  description = "Base URL for Story Fellow API"
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "input_bucket_name" {
  description = "Input content bucket"
  value       = aws_s3_bucket.input.bucket
}

output "output_bucket_name" {
  description = "Narration output bucket"
  value       = aws_s3_bucket.output.bucket
}

output "jobs_table_name" {
  description = "DynamoDB jobs table"
  value       = aws_dynamodb_table.jobs.name
}

output "notifications_topic_arn" {
  description = "SNS topic for completion/notification events"
  value       = aws_sns_topic.notifications.arn
}

output "website_bucket_name" {
  description = "Private website asset bucket"
  value       = var.deploy_website ? aws_s3_bucket.website[0].bucket : null
}

output "website_url" {
  description = "CloudFront URL hosting the Story Fellow web app"
  value       = var.deploy_website ? "https://${aws_cloudfront_distribution.website[0].domain_name}" : null
}
