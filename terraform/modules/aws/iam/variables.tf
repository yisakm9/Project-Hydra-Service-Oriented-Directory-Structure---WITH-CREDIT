variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 Vault to allow access to"
  type        = string
}

# We make this optional for now, but it will be used when we link SQS
variable "sqs_queue_arn" {
  description = "ARN of the SQS Queue for Hybrid operations"
  type        = string
  default     = "*" # Broad for now until SQS module is built, then we tighten it
}