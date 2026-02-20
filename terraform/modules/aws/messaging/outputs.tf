output "task_queue_url" {
  description = "URL for the Local Agent to poll for tasks"
  value       = aws_sqs_queue.task_queue.url
}

output "task_queue_arn" {
  description = "ARN for IAM permissions"
  value       = aws_sqs_queue.task_queue.arn
}

output "response_queue_url" {
  description = "URL for the Local Agent to send results"
  value       = aws_sqs_queue.response_queue.url
}