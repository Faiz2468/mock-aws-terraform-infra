output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app_data.bucket
}

output "ec2_instance_id" {
  value = aws_instance.app_server.id
}

output "iam_role_name" {
  value = aws_iam_role.ec2_app_role.name
}
