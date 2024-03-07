output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "private_ips" {
  value = data.aws_instances.application.private_ips
}
