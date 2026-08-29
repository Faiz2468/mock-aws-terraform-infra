variable "name_prefix" {
  description = "Prefix applied to all resource names/tags"
  type        = string
}

# --- Primary data bucket ---------------------------------------------------

resource "aws_s3_bucket" "app_data" {
  bucket = "${var.name_prefix}-app-data"

  tags = {
    Name = "${var.name_prefix}-app-data"
  }
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSE-S3 (AES256) used here rather than a customer-managed KMS key —
# accepted for this mock environment; a real deployment would add a KMS
# key with its own rotation/key policy.
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "app-data-access-logs/"
}

# --- Access logging target bucket ------------------------------------------
# Separate bucket to receive S3 server access logs from app_data.
# This bucket doesn't log itself (it IS the log destination) — tfsec's
# generic check still flags it, so that finding is accepted/documented.
#tfsec:ignore:aws-s3-enable-bucket-logging

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.name_prefix}-access-logs"

  tags = {
    Name = "${var.name_prefix}-access-logs"
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app_data.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.app_data.arn
}