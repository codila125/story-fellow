resource "aws_s3_bucket" "website" {
  count  = var.deploy_website ? 1 : 0
  bucket = local.website_bucket_name
}

resource "aws_s3_bucket_public_access_block" "website" {
  count  = var.deploy_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  count  = var.deploy_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "website" {
  count  = var.deploy_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_control" "website" {
  count                             = var.deploy_website ? 1 : 0
  name                              = "${local.name_prefix}-website-oac"
  description                       = "OAC for Story Fellow website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  count               = var.deploy_website ? 1 : 0
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website[0].bucket_regional_domain_name
    origin_id                = "website-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website[0].id
  }

  default_cache_behavior {
    target_origin_id       = "website-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "website" {
  count  = var.deploy_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "website_index" {
  count        = var.deploy_website ? 1 : 0
  bucket       = aws_s3_bucket.website[0].id
  key          = "index.html"
  content_type = "text/html"
  content      = replace(file("${path.module}/../../web/index.html"), "__API_BASE_URL__", aws_apigatewayv2_stage.prod.invoke_url)
  etag         = md5(replace(file("${path.module}/../../web/index.html"), "__API_BASE_URL__", aws_apigatewayv2_stage.prod.invoke_url))

  depends_on = [aws_s3_bucket_policy.website]
}
