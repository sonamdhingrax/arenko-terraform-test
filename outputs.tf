output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.nginx_lb.dns_name
}
