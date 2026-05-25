# Assumptions

This file captures the assumptions made, trade-offs accepted, and
known gaps due to the limitation of a personal AWS account.

---

## Environment & accounts

- Two AWS accounts exist in my personal org: `develop` and `prod`. In an enterprise setup there should be more than 2 accounts.
- The S3 state backend bucket is itself bootstrapped by `terraform_backend/`. Chicken-and-egg is solved by running that
  module with local state once, then never touching it again. This could be standardized as part of account creation so that the terrform repo can use it readily.
- s3 buckets should be encrypted using kms key.

## Secrets & sensitive files

- `*.tfvars` / `*.tfvars.json` are committed deliberately because this is an exercise and they hold no secrets. In a real repo they would be gitignored. Personally, I like to keep all the configuration local and as close as possible with the resource as I have done in the case of VPC and RDS by making use of `local` block.
- `manage_master_user_password = true` means the RDS master password never enters Terraform state. The Secrets Manager secret is
  encrypted with the module's CMK.

## Networking

- In a real world, I would not create a VPC by specifying the individual resource, it would be better to use the open-source VPC module provided by AWS.
- ALB listens on port 80(HTTP) only. No ACM cert because no domain name was provided. Port 443 + redirect would be added the moment a domain exists.
- I did not enable VPC flow logs or ALB access logs, but in an enterprise setup with regulatory complainces should enable those.
- Third AZ is _scaffolded_ (CIDR space + route table slots) but not deployed. Easy to extend.

## RDS / Aurora

- Aurora Serverless v2 Postgres 17.7 chosen as the current stable version. Postgres 13 (the original) is EOL in RDS as of 2026-02-28.
- Serveless v2 is chosen in this case because there is no load in the database and it remains scaled down to 0, but in prod environment and in a line of business appllication a right sized instance backed database would be more economical to use.
- Performance Insights retention is 7 days (free tier). Production would likely want 731.
- Since there is no data in the database, I did not want to create a backup_retention_period. In a production setup, it is strongly recommended to use backup_retention_period with preferred_backup_window defined based on the period of low trafic for the application.

## ECS

- Public ECR `nginx:latest` is the placeholder workload. A real service would pin a specific version of the image and the image should live in private ECR. Docker free tier has usage limits on the number of pulls we can do.
- Container count: 1 in non-prod, 2 in prod. In an real scenario, we should implement an auto-scaling strategy based on the relevant meteric.
- ECS Task role does not have any policies/permissions assigned. This is rarely the case in real scenrio where most of the services are in AWS.
