variable "project_name" {
  description = "Project slug used for resource naming."
  type        = string
  default     = "story-fellow"
}

variable "environment" {
  description = "Environment label for resource naming."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "python_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "log_retention_days" {
  description = "CloudWatch log retention for Lambda log groups."
  type        = number
  default     = 14
}

variable "lambda_memory_mb" {
  description = "Default Lambda memory size."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Default Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "polly_output_prefix" {
  description = "Output prefix used for generated Polly assets."
  type        = string
  default     = "output/"
}

variable "deploy_website" {
  description = "Whether to deploy the static website frontend."
  type        = bool
  default     = true
}
