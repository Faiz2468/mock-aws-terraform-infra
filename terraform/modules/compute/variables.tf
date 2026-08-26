variable "name_prefix" {
  description = "Prefix applied to all resource names/tags"
  type        = string
}

variable "subnet_id" {
  description = "Subnet the instance should launch into"
  type        = string
}

variable "security_group_id" {
  description = "Security group to attach to the instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
