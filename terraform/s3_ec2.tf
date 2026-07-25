# --- Storage layer --------------------------------------------------------
resource "aws_s3_bucket" "app_data" {
  bucket = "faiz-cloud-demo-app-data"

  tags = {
    Name = "faiz-cloud-demo-app-data"
  }
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Compute layer ----------------------------------------------------------
resource "aws_instance" "app_server" {
  ami                    = "ami-0abcdef1234567890" # placeholder; MiniStack does not validate AMI IDs
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_app_profile.name

  tags = {
    Name = "faiz-cloud-demo-app-server"
  }
}
