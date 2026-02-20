# --- 1. The Trust Policy ---
# Allows EC2 instances to assume this role
resource "aws_iam_role" "c2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# --- 2. The Permissions Policy ---
# Defines what the C2 server is allowed to do
resource "aws_iam_policy" "c2_policy" {
  name        = "${var.project_name}-c2-policy-${var.environment}"
  description = "Policy for C2 S3 backup and SQS hybrid tasking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 Access (Backups & Loot)
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      # SQS Access (Hybrid Local PC Tasking)
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# --- 3. Attach Policy to Role ---
resource "aws_iam_role_policy_attachment" "c2_attach" {
  role       = aws_iam_role.c2_role.name
  policy_arn = aws_iam_policy.c2_policy.arn
}

# --- 4. Instance Profile ---
# This is the "wrapper" that lets us attach the role to the EC2 Launch Template
resource "aws_iam_instance_profile" "c2_profile" {
  name = "${var.project_name}-instance-profile-${var.environment}"
  role = aws_iam_role.c2_role.name
}