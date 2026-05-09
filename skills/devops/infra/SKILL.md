# skill: devops/infra
# triggers: terraform, IaC, provision, cloudformation, infrastructure, hcl

## Module Structure
```
infra/
├── environments/{dev,staging,prod}/main.tf
├── modules/{vpc,eks,rds,iam,s3}/
└── shared/backend.tf
```

## Remote State
```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-${var.account_id}"
    key            = "${var.project}/${var.env}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
```

## Standard Variables
```hcl
variable "env"     { type = string }
variable "region"  { type = string; default = "us-east-1" }
variable "project" { type = string }
locals {
  tags = { env = var.env, project = var.project, managed-by = "terraform" }
}
```

## Workflow
```bash
terraform init -backend-config=env/${ENV}.tfbackend
terraform workspace select ${ENV} || terraform workspace new ${ENV}
terraform plan -var-file=env/${ENV}.tfvars -out=tfplan
terraform apply tfplan
terraform plan -detailed-exitcode  # drift detection
```

## Rules
- Modules per logical group; no monolithic root
- No hardcoded values — variables/locals only
- Tag every resource with locals.tags
- `terraform fmt` + `tflint` mandatory in CI
- Never apply without plan review in prod

## FORBIDDEN
```
FORBIDDEN: terraform apply without a plan file in prod.
FORBIDDEN: Hardcoded account IDs, ARNs, or region strings in module bodies.
FORBIDDEN: Storing secrets in tfvars files committed to Git.
FORBIDDEN: Single monolithic root module — use logical module splits.
```

## Gotchas

1. **`terraform destroy` with workspaces destroys the selected workspace only.** Verify `terraform workspace show` before any destructive command. Selecting wrong workspace = deleting the wrong environment.

2. **State locking doesn't prevent concurrent reads.** Two engineers can both run `terraform plan` simultaneously, both see "no changes," and then both apply conflicting changes. The lock only covers apply. Use required pull request reviews for prod applies.

3. **`depends_on` on modules hides parallelism.** Adding module-level `depends_on` serializes ALL resources in that module, even ones that could run in parallel. Prefer resource-level `depends_on` for targeted dependencies.

4. **Provider version constraints use `~>` incorrectly.** `~> 5.0` allows 5.x but not 6.x (correct). `~> 5` allows 5.x AND 6.x (probably not what you want). Always pin to the minor: `~> 5.0`.

5. **Remote state outputs across stacks are pull-time, not push-time.** `data.terraform_remote_state.vpc.outputs.vpc_id` reads at plan time — if the upstream stack's output changes after you've already planned, you're applying stale data.

## Related Skills
- **devops/gitops**: After writing Terraform, GitOps enforces that only Git-committed state gets applied
- **devops/cloud**: Module examples for VPC, EKS, RDS reference the cloud skill's AWS patterns
- **devops/cicd**: `terraform plan` + `apply` in CI requires OIDC auth from the cicd skill

## Verification Before Apply
```bash
# Always validate before planning
terraform validate
tflint --recursive

# Check for secrets in state
grep -r "password\|secret\|key" .terraform/ && echo "WARNING: potential secrets"

# Drift check
terraform plan -detailed-exitcode -var-file=env/${ENV}.tfvars
echo "Exit code 0=no change, 1=error, 2=changes pending"
```

## Module Pattern (VPC example)
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = local.tags
}

resource "aws_subnet" "public" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, count.index)
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.tags, { "kubernetes.io/role/elb" = "1" })
}

# modules/vpc/outputs.tf
output "vpc_id"        { value = aws_vpc.main.id }
output "public_subnets" { value = aws_subnet.public[*].id }
```

## Common Module Calls
```hcl
module "vpc" {
  source  = "./modules/vpc"
  cidr    = "10.0.0.0/16"
  azs     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  project = var.project
  env     = var.env
}

module "eks" {
  source     = "./modules/eks"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  project    = var.project
  env        = var.env
}
```

## Terragrunt (DRY across envs)
```hcl
# terragrunt.hcl — root
remote_state {
  backend = "s3"
  config = {
    bucket         = "tf-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}

# environments/prod/vpc/terragrunt.hcl
include "root" { path = find_in_parent_folders() }
terraform { source = "../../../modules//vpc" }
inputs = { cidr = "10.0.0.0/16", azs = ["us-east-1a", "us-east-1b"] }
```
