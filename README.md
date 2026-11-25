# Mock-AWS Infrastructure with Terraform + MiniStack

Infrastructure-as-Code project provisioning a mock AWS environment - VPC,
subnets, security groups, IAM roles, S3, and EC2 - entirely on free,
open-source tooling.

## Why this exists

This repo demonstrates a structure without needing a paid AWS account: every
resource here would deploy identically against real AWS by swapping the
provider `endpoints` block.

## Stack

- **[MiniStack](https://github.com/ministackorg/ministack)** - free,
  MIT-licensed local AWS emulator (S3, EC2, IAM, VPC, and 50+ other
  services on one Docker image)
- **Terraform** - infrastructure as code
- **GitHub Actions** - CI pipeline running `terraform fmt`, `validate`,
  `tflint`, `tfsec`, and `checkov` on every PR

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

CI runs [tfsec](https://github.com/aquasecurity/tfsec) and
[Checkov](https://github.com/bridgecrewio/checkov) on every push to catch
misconfigurations before they'd ever reach a real AWS account. Checkov
currently reports 52 passed, 0 failed and 13 skipped checks, and every skip
has a written reason next to the resource it applies to.

**Fixed:**
- SSH restricted to a specific admin CIDR (not open to the internet)
- S3 buckets: public access blocked, server-side encryption enabled,
  versioning enabled, access logging enabled to a dedicated log bucket
- EC2: root volume encrypted, IMDSv2 enforced (blocks unauthenticated
  metadata service access), detailed monitoring and EBS optimization enabled
- VPC default security group locked down (no rules, so no traffic)
- Security group egress rule has an explicit description

**Accepted risk (documented inline with `#tfsec:ignore`, `#checkov:skip` and comments):**
- Public HTTP/HTTPS ingress - intentional, this is a public-facing web
  server
- Public IP on the public subnet - intentional for the same reason
- Unrestricted egress - acceptable for this demo; a real deployment
  would scope this to required destinations
- No VPC flow logs - would need a CloudWatch log group + IAM role;
  omitted to avoid infra MiniStack can't exercise
- SSE-S3 (AES256) instead of a customer-managed KMS key - adequate for
  this environment; a production deployment would add a dedicated KMS
  key with its own rotation policy
- S3 cross-region replication, lifecycle rules and event notifications -
  these add cost and downstream infrastructure that MiniStack can't
  exercise; a production deployment would define retention and replication
- Checkov's "security group not attached" finding (`CKV2_AWS_5`) is a false
  positive: the group is attached to the EC2 instance through a module
  variable, and Checkov can't trace values across module boundaries

This mirrors how a real security review works: not every finding gets
"fixed" by locking everything down - some are accepted as reasonable
tradeoffs, but every decision is documented rather than silently
suppressed.

## Disaster recovery

**Scenario:** a critical object in the app data bucket (`faiz-cloud-dev-app-data`) is accidentally overwritten or corrupted, for example by a bad deploy script or human error.

**Mechanism:** S3 versioning is enabled on the bucket in `terraform/modules/storage`. Every write creates a new version instead of destroying the old one, so earlier states stay recoverable after an overwrite.

**Recovery drill (run against MiniStack):**

```bash
# 0. Seed test data
echo "critical business data - v1" > test-file.txt
aws --endpoint-url=http://localhost:4566 s3 cp test-file.txt s3://faiz-cloud-dev-app-data/ --checksum-algorithm SHA256

# 1. Simulate the incident: overwrite with corrupted content
echo "CORRUPTED - accidental overwrite v2" > test-file.txt
aws --endpoint-url=http://localhost:4566 s3 cp test-file.txt s3://faiz-cloud-dev-app-data/ --checksum-algorithm SHA256

# 2. Find the last known-good version
aws --endpoint-url=http://localhost:4566 s3api list-object-versions --bucket faiz-cloud-dev-app-data --no-cli-pager

# 3. Download that specific version
aws --endpoint-url=http://localhost:4566 s3api get-object --bucket faiz-cloud-dev-app-data --key test-file.txt --version-id <VersionId> restored-file.txt

# 4. Re-upload it as the current live version
aws --endpoint-url=http://localhost:4566 s3 cp restored-file.txt s3://faiz-cloud-dev-app-data/test-file.txt --checksum-algorithm SHA256

# 5. Verify
aws --endpoint-url=http://localhost:4566 s3 cp s3://faiz-cloud-dev-app-data/test-file.txt -
```

**Recovery targets:**
- **RPO:** near zero. Versioning captures every write, so nothing written before the incident is lost.
- **RTO:** under 5 minutes. The drill above took a few minutes by hand, with no data reconstruction needed.

**Notes:**
- `--checksum-algorithm SHA256` is needed because MiniStack doesn't support the AWS CLI's newer default checksum type. Real S3 doesn't need it.
- MiniStack didn't honor `?versionId=` in a `copy-object` source, so the drill uses download-then-re-upload instead. Against real S3, `copy-object` with a version ID also works.

## CloudFormation equivalent

`cloudformation/storage.yaml` provisions the same storage layer as `terraform/modules/storage` (an app data bucket and an access logs bucket, with versioning, AES256 encryption, public access blocked and access logging), written as a CloudFormation template. It lets the same infrastructure be compared across both IaC tools.

```bash
# Lint the template
pip install cfn-lint
cfn-lint cloudformation/storage.yaml

# Deploy to MiniStack
aws --endpoint-url=http://localhost:4566 cloudformation create-stack --stack-name faiz-storage --template-body file://cloudformation/storage.yaml

# Check the stack and the buckets
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks --stack-name faiz-storage --no-cli-pager
aws --endpoint-url=http://localhost:4566 s3 ls
```

**Emulator limitation:** the template passes `cfn-lint` cleanly and the stack reaches `CREATE_COMPLETE`. Against MiniStack, versioning was applied, but `BucketEncryption` and `PublicAccessBlockConfiguration` were not (`get-bucket-encryption` and `get-public-access-block` report nothing configured). That appears to be a gap in MiniStack's CloudFormation engine rather than the template. Access logging was not checked, and the template has not been run against real AWS.

## Running it locally

```bash
# 1. Start MiniStack
docker compose up -d

# 2. Provision the mock AWS stack
cd terraform/environments/dev
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

To run the policy scan locally:

```bash
pip install checkov
checkov -d terraform --framework terraform --compact --quiet
```

## What this demonstrates

- VPC design: CIDR planning, public subnet, internet gateway, route tables
- Security groups with explicit, minimal ingress rules
- IAM least-privilege role/policy design (EC2 role scoped to one S3 bucket only)
- Terraform module structure and state management
- Automated security scanning (tfsec and Checkov policy-as-code) integrated
  into CI, with a documented remediation and risk-acceptance process
- CI validation on every pull request
- Disaster recovery: S3 versioning-based restore drill with documented RPO/RTO targets
- CloudFormation: the storage layer written as a lint-checked template (`cfn-lint`) and deployed to MiniStack alongside the Terraform version, with the emulator's limits documented

## Notes

- AMI IDs are placeholders - MiniStack doesn't validate them, but the
  resource definitions are AWS-API-accurate and would work unchanged
  against a real AWS account.
- The EC2 instance sets `ebs_optimized = true` to satisfy Checkov. Older
  instance types such as `t2.micro` don't support EBS optimization on real
  AWS, so a real deployment would switch to a type like `t3.micro`.
- `PERSIST_STATE` is enabled in `docker-compose.yml` so state survives
  container restarts during local development.