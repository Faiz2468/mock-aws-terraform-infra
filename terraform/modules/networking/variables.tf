variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AZ to place the public subnet in"
  type        = string
  default     = "us-east-1a"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names/tags"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR range allowed to SSH into instances (restrict to your own IP in real deployments)"
  type        = string
  default     = "203.0.113.0/32" # TEST-NET-3 placeholder — replace with your actual IP
}