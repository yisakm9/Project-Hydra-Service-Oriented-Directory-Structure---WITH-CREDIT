output "c2_callback_domain" {
  description = "The CloudFront Domain (Use this in your malware)"
  value       = module.cdn.cloudfront_domain_name
}

output "alb_direct_dns" {
  description = "The ALB DNS (For debugging, do not use in malware)"
  value       = module.load_balancing.alb_dns_name
}

output "s3_vault_name" {
  description = "The S3 Bucket Name for Manual Uploads"
  value       = module.storage.bucket_name
}

output "sqs_task_url" {
  description = "The SQS URL for your Local Python Agent"
  value       = module.messaging.task_queue_url
}

output "sqs_response_url" {
  description = "The SQS URL for Local Agent Responses"
  value       = module.messaging.response_queue_url
}