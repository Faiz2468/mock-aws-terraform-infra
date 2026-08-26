# --- Dev environment -----------------------------------------------------
# Wires the networking, storage, iam, and compute modules together for
# the "dev" environment. A "staging" or "prod" environment would be a
# sibling folder calling the same modules with different variable values
# (bigger CIDR range, different instance_type, etc.) and its own state.

locals {
  name_prefix = "faiz-cloud-dev"
}

module "networking" {
  source      = "../../modules/networking"
  name_prefix = local.name_prefix
}

module "storage" {
  source      = "../../modules/storage"
  name_prefix = local.name_prefix
}

module "iam" {
  source        = "../../modules/iam"
  name_prefix   = local.name_prefix
  s3_bucket_arn = module.storage.bucket_arn
}

module "compute" {
  source                = "../../modules/compute"
  name_prefix           = local.name_prefix
  subnet_id             = module.networking.public_subnet_id
  security_group_id     = module.networking.security_group_id
  iam_instance_profile  = module.iam.instance_profile_name
}
