# Terraform state backend

Creates the S3 bucket that stores Terraform state for the rest of this
project. The bucket is self-hosted: its own state lives in the bucket
once bootstrapped.

## Layout

```
terraform_backend/
├── accounts.tf       # local.environment map: env name -> AWS account id
├── main.tf           # S3 bucket + versioning + SSE + access controls
├── outputs.tf
├── variables.tf
├── provider.tf       # backend "s3" {} — populated at init time
└── envs/
    ├── develop.tfbackend   # bucket / key / region per env
    └── prod.tfbackend
```

Per-environment backend settings live in `envs/<env>.tfbackend` because
the `backend` block cannot reference variables or locals — it is read by
`terraform init` before variable values are available.

## Selecting an environment

All commands below assume the target environment is exported as a shell
variable. Terraform automatically maps `TF_VAR_<name>` to `var.<name>`:

```sh
export TF_VAR_environment=develop
```

Re-export when switching to `prod`. No `-var-file` flags required.

## Bootstrap (first time only)

The backend bucket cannot exist before it is created, so the first apply
must use local state. Steps:

1. **Comment out** the `backend "s3" {}` block in `provider.tf` so
   Terraform falls back to a local state file:
   ```hcl
   # backend "s3" {}
   ```
2. Initialise locally and create the bucket:
   ```sh
   terraform init
   terraform apply
   ```
3. **Uncomment** the `backend "s3" {}` block in `provider.tf`.
4. Migrate the local state into the freshly-created bucket:
   ```sh
   terraform init -backend-config=envs/develop.tfbackend -migrate-state
   ```
5. Delete the leftover `terraform.tfstate` and `terraform.tfstate.backup`
   files once you have confirmed the state object exists in S3:
   ```sh
   aws s3 ls s3://arenko-tftest-tfstate-822725963102/terraform_backend/
   rm terraform.tfstate terraform.tfstate.backup
   ```

## When to come back here

This module is a one-time bootstrap. After migration nothing in here is
re-applied during day-to-day work. Come back only to:

- add a new environment (extend `local.environment` in `accounts.tf`
  and add a matching `envs/<env>.tfbackend`),
- change the bucket configuration itself (encryption, versioning,
  lifecycle)

## Why this is shaped the way it is

- **`use_lockfile = true`** (S3-native locking, Terraform 1.10+) replaces
  the older `dynamodb_table` lock pattern. One less resource to manage,
  one less IAM permission to grant.
- **`prevent_destroy = true`** on the bucket: a stray `terraform destroy`
  would otherwise nuke every state file in the project.
- **`BucketOwnerEnforced`** ownership disables ACLs entirely; access is
  controlled exclusively by bucket policy and IAM.
- **`accounts.tf`** holds the env-to-account-id map. Only `develop` has
  a real account today; `prod` is a placeholder so multi-env wiring
  (cross-account assume-role, per-env state buckets) can be added
  without further restructuring.
