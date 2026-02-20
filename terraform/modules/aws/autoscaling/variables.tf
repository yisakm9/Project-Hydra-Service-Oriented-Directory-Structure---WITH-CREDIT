variable "project_name" { type = string }
variable "environment"  { type = string }
variable "vpc_id"       { type = string }

variable "subnet_ids" {
  description = "List of public subnet IDs for the ASG to launch instances into"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups to attach to the instances"
  type        = list(string)
}

variable "target_group_arns" {
  description = "ALB Target Group ARNs to register instances with"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "The IAM Instance Profile allowing access to S3/SQS"
  type        = string
}

variable "user_data_base64" {
  description = "Base64 encoded User Data script (The 'Phoenix' Logic)"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t4g.large" # ARM64 Architecture
}