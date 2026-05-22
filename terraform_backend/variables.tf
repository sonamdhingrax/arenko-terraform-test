variable "region" {
  description = "AWS region in which the state bucket is created."
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "The environment name. Must be a key in local.environment (see accounts.tf)."
  type        = string

  validation {
    condition     = contains(["develop", "prod"], var.environment)
    error_message = "environment must be one of: develop, prod."
  }
}
