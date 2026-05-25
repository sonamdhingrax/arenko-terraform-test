data "aws_caller_identity" "current" {}

# --- KMS key for storage encryption -------------------------------------------

resource "aws_kms_key" "rds" {
  description             = "${var.environment} RDS encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.environment}-rds-key"
  }
}

# --- Database security group --------------------------------------------------

resource "aws_security_group" "database_sgrp" {
  name        = "${var.environment}-sgrp-database"
  description = "Allow inbound traffic from application security group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "app_to_db_ingress" {
  security_group_id            = aws_security_group.database_sgrp.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.app_security_group_id
}

# --- Subnet group -------------------------------------------------------------

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids
}

# --- Enhanced Monitoring IAM role ---------------------------------------------

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

# --- Cluster ------------------------------------------------------------------

resource "aws_rds_cluster" "postgresql_cluster" {
  cluster_identifier            = "${var.environment}-postgresql-cluster"
  engine                        = "aurora-postgresql"
  engine_version                = var.engine_version
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

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverlessv2_scaling_configuration != null ? [1] : []
    content {
      min_capacity = var.serverlessv2_scaling_configuration.min_capacity
      max_capacity = var.serverlessv2_scaling_configuration.max_capacity
    }
  }

  lifecycle {
    ignore_changes = [
      master_username,
      master_password,
      final_snapshot_identifier
    ]
  }
}

resource "aws_rds_cluster_instance" "instance_a" {
  cluster_identifier   = aws_rds_cluster.postgresql_cluster.id
  identifier           = "${var.environment}-postgresql-instance-a"
  engine               = "aurora-postgresql"
  engine_version       = var.engine_version
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  instance_class       = var.instance_class

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}

resource "aws_rds_cluster_instance" "instance_b" {
  count                = (var.create_instance_b || var.environment == "prod") ? 1 : 0
  cluster_identifier   = aws_rds_cluster.postgresql_cluster.id
  identifier           = "${var.environment}-postgresql-instance-b"
  engine               = "aurora-postgresql"
  engine_version       = var.engine_version
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  instance_class       = var.instance_class

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}
