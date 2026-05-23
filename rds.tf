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

resource "aws_security_group" "database_sgrp" {
  name        = "${var.environment}-sgrp-database"
  description = "Allow inbound traffic from application security group"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "app_to_db_ingress" {
  security_group_id            = aws_security_group.database_sgrp.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sgrp.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id
}

data "aws_iam_policy_document" "rds_monitoring_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name               = "${var.environment}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_trust.json
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster" "postgresql_cluster" {
  cluster_identifier            = "${var.environment}-postgresql-cluster"
  engine                        = "aurora-postgresql"
  engine_version                = local.config[var.environment].engine_version
  db_subnet_group_name          = aws_db_subnet_group.db_subnet_group.id
  database_name                 = "mydb"
  final_snapshot_identifier     = "${var.environment}-postgresql-cluster-final-snapshot-${formatdate("DDMMYYYY", timestamp())}"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.id
  master_username               = "rds_admin"
  vpc_security_group_ids        = [aws_security_group.database_sgrp.id]
  storage_encrypted             = true
  kms_key_id                    = aws_kms_key.rds.arn

  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  deletion_protection = true
  skip_final_snapshot = false

  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.config[var.environment].serverlessv2_scaling_configuration != null ? [1] : []
    content {
      min_capacity = local.config[var.environment].serverlessv2_scaling_configuration.min_capacity
      max_capacity = local.config[var.environment].serverlessv2_scaling_configuration.max_capacity
    }
  }

  lifecycle {
    ignore_changes = [
      master_username,
      master_password
    ]
  }
}

resource "aws_rds_cluster_instance" "instance_a" {
  cluster_identifier   = aws_rds_cluster.postgresql_cluster.id
  identifier           = "${var.environment}-postgresql-instance-a"
  engine               = "aurora-postgresql"
  engine_version       = local.config[var.environment].engine_version
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  instance_class       = local.config[var.environment].instance_class

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}

resource "aws_rds_cluster_instance" "instance_b" {
  count                = local.config[var.environment].create_instance_b != null ? (local.config[var.environment].create_instance_b ? 1 : 0) : (try(var.environment == "prod" ? 1 : 0, 0))
  cluster_identifier   = aws_rds_cluster.postgresql_cluster.id
  identifier           = "${var.environment}-postgresql-instance-b"
  engine               = "aurora-postgresql"
  engine_version       = local.config[var.environment].engine_version
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  instance_class       = local.config[var.environment].instance_class

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}
