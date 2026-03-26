# ==============================================================================
# GCP MESSAGING MODULE
# Cloud Pub/Sub (replaces AWS SQS)
# ==============================================================================

# --- 1. Task Topic & Subscription (Cloud -> Local PC) ---
resource "google_pubsub_topic" "task_topic" {
  name = "${var.project_name}-tasks-${var.environment}"

  # Messages encrypted at rest by default
  labels = {
    project = var.project_name
  }
}

resource "google_pubsub_subscription" "task_subscription" {
  name  = "${var.project_name}-tasks-sub-${var.environment}"
  topic = google_pubsub_topic.task_topic.id

  # Messages expire if not picked up in 1 day (same as SQS retention)
  message_retention_duration = "86400s"
  ack_deadline_seconds       = 20

  # Enable exactly-once delivery for reliability
  enable_exactly_once_delivery = true
}

# --- 2. Response Topic & Subscription (Local PC -> Cloud) ---
resource "google_pubsub_topic" "response_topic" {
  name = "${var.project_name}-responses-${var.environment}"

  labels = {
    project = var.project_name
  }
}

resource "google_pubsub_subscription" "response_subscription" {
  name  = "${var.project_name}-responses-sub-${var.environment}"
  topic = google_pubsub_topic.response_topic.id

  message_retention_duration = "86400s"
  ack_deadline_seconds       = 20
  enable_exactly_once_delivery = true
}
