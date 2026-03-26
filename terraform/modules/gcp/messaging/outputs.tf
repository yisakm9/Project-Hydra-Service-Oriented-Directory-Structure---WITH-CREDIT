output "task_topic_name" {
  description = "Name of the task Pub/Sub topic"
  value       = google_pubsub_topic.task_topic.name
}

output "task_subscription_name" {
  description = "Name of the task subscription"
  value       = google_pubsub_subscription.task_subscription.name
}

output "response_topic_name" {
  description = "Name of the response Pub/Sub topic"
  value       = google_pubsub_topic.response_topic.name
}

output "response_subscription_name" {
  description = "Name of the response subscription"
  value       = google_pubsub_subscription.response_subscription.name
}
