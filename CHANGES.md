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
- Renamed the deployed environment from `test` to `develop` in `terraform.tfvars.json` to match the convention used by the backend
  module (`develop` / `prod`). I have also created 2 AWS accounts (`develop` and `prod`) in my personal AWS organization.
- Created `terraform_backend/`, a self-hosted Terraform module that provisions the S3 bucket used as the state backend for every other
  Terraform working directory in this repo.
- Wired the root configuration to use the same bucket under a distinct
  state key (`root/terraform.tfstate`) via a partial `backend "s3" {}`
  block plus `envs/develop.tfbackend`.
