variable "name_prefix" {
  description = "Prefix applied to all resource names/tags"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket the EC2 role should be scoped to"
  type        = string
}
