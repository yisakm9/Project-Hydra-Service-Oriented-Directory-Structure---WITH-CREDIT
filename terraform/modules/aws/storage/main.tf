resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- 1. The Main Bucket ---
resource "aws_s3_bucket" "hydra_vault" {
  bucket = "${var.project_name}-vault-${var.environment}-${random_id.bucket_suffix.hex}"

  # Force destroy allows terraform destroy to work even if bucket has files
  # Set to false in real production to prevent accidental data loss
  force_destroy = false

  tags = {
    Name    = "${var.project_name}-s3-${var.environment}"
    Project = var.project_name
  }
}

# --- 2. Security: Encryption ---
resource "aws_s3_bucket_server_side_encryption_configuration" "vault_encryption" {
  bucket = aws_s3_bucket.hydra_vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- 3. Resilience: Versioning ---
# Critical for the "Phoenix" strategy. Allows rollback of C2 state.
resource "aws_s3_bucket_versioning" "vault_versioning" {
  bucket = aws_s3_bucket.hydra_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- 4. Security: Block Public Access ---
# Absolutely no public access. Only IAM roles can touch this.
resource "aws_s3_bucket_public_access_block" "vault_block" {
  bucket = aws_s3_bucket.hydra_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}