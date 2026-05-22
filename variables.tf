variable "environment" {
  description = "the environment name. Must be one of: develop, prod."
  type        = string

  validation {
    condition     = contains(["develop", "prod"], var.environment)
    error_message = "environment must be one of: develop, prod."
  }
}

variable "service" {
  description = "the service name"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-2"
}
