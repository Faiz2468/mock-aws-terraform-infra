output "vpc_id" {
  value = module.networking.vpc_id
}

output "subnet_id" {
  value = module.networking.public_subnet_id
}

output "security_group_id" {
  value = module.networking.security_group_id
}

output "s3_bucket_name" {
  value = module.storage.bucket_name
}

output "iam_role_name" {
  value = module.iam.role_name
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}
