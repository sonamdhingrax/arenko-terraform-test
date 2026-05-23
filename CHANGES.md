# Changes

A running log of the decisions, assumptions, and trade-offs made while
fixing this Terraform exercise. Read this before the code if you want
the _why_; read the code for the _what_.

The PRs are listed in the order they were authored. Each section
describes a single logical unit of work.

---

## PR #0 — baseline scaffolding and remote state backend

### What changed

- Added `provider.tf` declaring Terraform `>= 1.12.2`, AWS provider
  `~> 6.0`, and a `provider "aws"` block parameterised by `var.region`.
- Added types and a `region` default to `variables.tf`.
- Added `.gitignore` for terraform and adjusted it to allow `*.tfvars` and `*.tfvars.json` for the purpose of exercise since they do not expose any secrets.
  module (`develop` / `prod`). I have also created 2 AWS accounts (`develop` and `prod`) in my personal AWS organization.
- Created `terraform_backend/`, a self-hosted Terraform module that provisions the S3 bucket used as the state backend for every other
  Terraform working directory in this repo.
- Wired the root configuration to use the same bucket under a distinct
  state key (`root/terraform.tfstate`) via a partial `backend "s3" {}`
  block plus `envs/develop.tfbackend`.
- Added `provider.tf` at the repo root with `terraform { required_version, required_providers, backend "s3" {} }` and a `provider "aws"` block parameterised by `var.region`.
- Added `type` and a `region` default to `variables.tf`.
- Renamed the deployed environment from `test` to `develop` in `terraform.tfvars.json` to match the backend module convention.
- Added `envs/develop.tfbackend` so `terraform init -backend-config=envs/develop.tfbackend` points the root at `s3://arenko-tftest-tfstate-822725963102/root/terraform.tfstate`.
- Initialized terraform with `terraform init -backend-config=envs/develop.tfbackend` so that all changes from now on use the remote backend.

## PR #2 - Fixed bugs and updates for improving security

### What changed

**VPC and networking (`vpc.tf`)**

- Lifted the VPC out of `main.tf` into a new `vpc.tf` for separation of concerns and that it can later be promoted to a module.
- Fixed the subnet CIDR range clashes and added config for prod as well.
- Renamed Subnets for clarity. `Web` and `Public` convey the same meaning. Used `Public` and `Private` names.
- Created a regional NAT GW instead of zonal
- Allowed for expansion/extension to a third AZ.
- Separate Route Tables for each tier.

**ALB (`lb.tf`)**

- Fixed `var.env` -> `var.environment` typo.
- Created a new security group for ALB to allow ingress on port 80 and 443. We do not have a domain name, so we cannot issue an ACM certificate and hence port 443 cannot be used.
- We do not want to make use of aws_lb_target_group_attachment, it will be created by the ECS service.
