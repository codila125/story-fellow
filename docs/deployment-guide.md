# Deployment Guide

## Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.6
- `uv` installed
- Permissions for Lambda, API Gateway, S3, CloudFront, DynamoDB, SNS, EventBridge, IAM, CloudWatch

## 1. Install local dependencies
```bash
uv sync --all-groups
uv run ruff check .
```

## 2. Configure Terraform variables
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# edit values if needed
```

## 3. Deploy infrastructure
```bash
terraform init
terraform plan
terraform apply
```

## 4. Capture endpoints
```bash
terraform output api_base_url
terraform output website_url
```

## 5. Validate flow
- Open `website_url` in browser
- Confirm API base URL is auto-populated
- Submit a text job and verify status transitions to `COMPLETED`

## 6. Destroy (when needed)
```bash
terraform destroy
```
