# --- Compute module ----------------------------------------------------
# EC2 instance wired into the networking module's subnet/security group
# and the IAM module's instance profile. Kept as its own module since
# it's the piece most likely to vary (instance type, count, AMI) between
# environments.

resource "aws_instance" "app_server" {
  ami                    = "ami-0abcdef1234567890" # placeholder; MiniStack does not validate AMI IDs
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  metadata_options {
    http_tokens                 = "required" # enforce IMDSv2
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.name_prefix}-app-server"
  }
}

output "instance_id" {
  value = aws_instance.app_server.id
}