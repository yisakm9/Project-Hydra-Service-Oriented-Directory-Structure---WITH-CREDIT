# --- 1. Task Queue (Cloud -> Local PC) ---
resource "aws_sqs_queue" "task_queue" {
  name                      = "${var.project_name}-tasks-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 86400  # 1 Day (Tasks expire if not picked up)
  receive_wait_time_seconds = 20     # Long Polling (Reduces API calls/Cost)

  # Server-Side Encryption (OpSec: Encrypts command data at rest)
  sqs_managed_sse_enabled = true

  tags = {
    Name = "Hydra-Task-Queue"
  }
}

# --- 2. Response Queue (Local PC -> Cloud) ---
resource "aws_sqs_queue" "response_queue" {
  name                      = "${var.project_name}-responses-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "Hydra-Response-Queue"
  }
}