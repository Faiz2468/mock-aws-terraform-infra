# Mock-AWS Infrastructure with Terraform + MiniStack

Infrastructure-as-Code project provisioning a mock AWS environment — VPC,
subnets, security groups, IAM roles, S3, and EC2 — entirely on free,
open-source tooling.

## Why this exists

This repo demonstrates a structure without needing a paid AWS account: every
resource here would deploy identically against real AWS by swapping the
provider `endpoints` block.

## Stack

- **[MiniStack](https://github.com/ministackorg/ministack)** — free,
  MIT-licensed local AWS emulator (S3, EC2, IAM, VPC, and 50+ other
  services on one Docker image)
- **Terraform** — infrastructure as code
- **GitHub Actions** — CI pipeline running `terraform fmt`, `validate`,
  `tflint`, and `tfsec` on every PR

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
           (t2.micro, app) (least-priv) (app data)
                    |
           S3 Access Logs Bucket
```

## Security scanning

CI runs [tfsec](https://github.com/aquasecurity/tfsec) on every push to
catch misconfigurations before they'd ever reach a real AWS account.

**Fixed:**
- SSH restricted to a specific admin CIDR (not open to the internet)
- S3 buckets: public access blocked, server-side encryption enabled,
  versioning enabled, access logging enabled to a dedicated log bucket
- EC2: root volume encrypted, IMDSv2 enforced (blocks unauthenticated
  metadata service access)
- Security group egress rule has an explicit description

**Accepted risk (documented inline with `#tfsec:ignore` and comments):**
- Public HTTP/HTTPS ingress — intentional, this is a public-facing web
  server
- Unrestricted egress — acceptable for this demo; a real deployment
  would scope this to required destinations
- No VPC flow logs — would need a CloudWatch log group + IAM role;
  omitted to avoid infra MiniStack can't exercise
- SSE-S3 (AES256) instead of a customer-managed KMS key — adequate for
  this environment; a production deployment would add a dedicated KMS
  key with its own rotation policy

This mirrors how a real security review works: not every finding gets
"fixed" by locking everything down — some are accepted as reasonable
tradeoffs, but every decision is documented rather than silently
suppressed.

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
- Automated security scanning (tfsec) integrated into CI, with a
  documented remediation and risk-acceptance process
- CI validation on every pull request

## Notes

- AMI IDs are placeholders — MiniStack doesn't validate them, but the
  resource definitions are AWS-API-accurate and would work unchanged
  against a real AWS account.
- `PERSIST_STATE` is enabled in `docker-compose.yml` so state survives
  container restarts during local development.

