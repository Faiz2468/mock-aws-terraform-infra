# --- IAM layer ----------------------------------------------------------
# Demonstrates least-privilege role design: an EC2 instance role that
# can only read/write to the one S3 bucket it needs, nothing else.

resource "aws_iam_role" "ec2_app_role" {
  name = "faiz-cloud-demo-ec2-role"

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
}

resource "aws_iam_policy" "s3_read_write" {
  name        = "faiz-cloud-demo-s3-access"
  description = "Least-privilege access to the app's S3 bucket only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_data.arn,
          "${aws_s3_bucket.app_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = aws_iam_policy.s3_read_write.arn
}

resource "aws_iam_instance_profile" "ec2_app_profile" {
  name = "faiz-cloud-demo-ec2-profile"
  role = aws_iam_role.ec2_app_role.name
}
