variable "name_prefix" {
  description = "Prefix applied to all resource names/tags"
  type        = string
}

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

output "bucket_name" {
  value = aws_s3_bucket.app_data.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.app_data.arn
}
