output "cluster_endpoint" {
  description = "Writer endpoint for the cluster."
  value       = aws_rds_cluster.postgresql_cluster.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the cluster."
  value       = aws_rds_cluster.postgresql_cluster.reader_endpoint
}

output "security_group_id" {
  description = "Database security group ID."
  value       = aws_security_group.database_sgrp.id
}
