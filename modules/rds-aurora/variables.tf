variable "environment" {
  description = "Environment name (e.g. develop, prod). Used for resource naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC the database security group will live in."
  type        = string
}

variable "database_subnet_ids" {
  description = "Private database subnet IDs across at least two AZs."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the application that may connect to the database on 5432."
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
}

variable "instance_class" {
  description = "Instance class for cluster instances. Use 'db.serverless' for Serverless v2."
  type        = string
}

variable "serverlessv2_scaling_configuration" {
  description = "Optional scaling bounds for Serverless v2. Set null for provisioned instances."
  type = object({
    min_capacity = number
    max_capacity = number
  })
}

variable "create_instance_b" {
  description = "Whether to create a second cluster instance."
  type        = bool
  default     = false
}
