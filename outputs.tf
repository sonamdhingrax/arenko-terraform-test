output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.nginx_alb.dns_name
}

output "database_writer_endpoint" {
  description = "Writer endpoint for the database cluster."
  value       = module.rds.cluster_endpoint
}

output "database_reader_endpoint" {
  description = "Reader endpoint for the database cluster."
  value       = module.rds.cluster_reader_endpoint
}
