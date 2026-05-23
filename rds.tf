locals {
  config = {
    develop = {
      engine_version = "17.7"
      instance_class = "db.serverless"
      serverlessv2_scaling_configuration = {
        min_capacity = 0
        max_capacity = 1
      }
      create_instance_b = false
    }
    prod = {
      engine_version = "17.7"
      instance_class = "db.serverless"
      serverlessv2_scaling_configuration = {
        min_capacity = 1
        max_capacity = 2
      }
    }
  }
}

module "rds" {
  source = "./modules/rds-aurora"

  environment                        = var.environment
  vpc_id                             = aws_vpc.vpc.id
  database_subnet_ids                = aws_subnet.database[*].id
  app_security_group_id              = aws_security_group.ecs_sgrp.id
  engine_version                     = local.config[var.environment].engine_version
  instance_class                     = local.config[var.environment].instance_class
  serverlessv2_scaling_configuration = local.config[var.environment].serverlessv2_scaling_configuration
  create_instance_b                  = local.config[var.environment].create_instance_b
}
