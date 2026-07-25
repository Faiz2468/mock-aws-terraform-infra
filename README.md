# Mock-AWS Infrastructure with Terraform + MiniStack

Infrastructure-as-Code project provisioning a mock AWS environment — VPC,
subnets, security groups, IAM roles, S3, and EC2 — entirely on free,
open-source tooling. No AWS account, no billing, no credit card anywhere
in this stack.

## Why this exists

Cloud infrastructure roles ask for hands-on AWS/IaC experience. This repo
demonstrates that skill set without needing a paid AWS account: every
resource here would deploy identically against real AWS by swapping the
provider `endpoints` block.

## Stack

- **[MiniStack](https://github.com/ministackorg/ministack)** — free,
  MIT-licensed local AWS emulator (S3, EC2, IAM, VPC, and 50+ other
  services on one Docker image)
- **Terraform** — infrastructure as code
- **GitHub Actions** — CI pipeline running `terraform fmt`, `validate`,
  and `tflint` on every PR

## Architecture

```
                     Internet Gateway
                            |
                     Route Table (public)
                            |
   VPC (10.0.0.0/16) -- Public Subnet (10.0.1.0/24)
                            |
                     Security Group (80/443/22)
                            |
                      EC2 Instance ---- IAM Role ---- S3 Bucket
                    (t2.micro, app)   (least-priv)   (app data)
```

## Running it locally

```bash
# 1. Start MiniStack
docker compose up -d

# 2. Provision the mock AWS stack
cd terraform
terraform init
terraform plan
terraform apply

# 3. Inspect what was created
terraform output
aws --endpoint-url=http://localhost:4566 ec2 describe-instances
aws --endpoint-url=http://localhost:4566 s3 ls

# 4. Tear down
terraform destroy
docker compose down
```

## What this demonstrates

- VPC design: CIDR planning, public subnet, internet gateway, route tables
- Security groups with explicit, minimal ingress rules
- IAM least-privilege role/policy design (EC2 role scoped to one S3 bucket only)
- Terraform module structure and state management
- CI validation on every pull request

## Notes

- AMI IDs are placeholders — MiniStack doesn't validate them, but the
  resource definitions are AWS-API-accurate and would work unchanged
  against a real AWS account.
- `PERSIST_STATE` is enabled in `docker-compose.yml` so state survives
  container restarts during local development.
