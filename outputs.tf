output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnets" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "alb" {
  value = aws_lb.alb.dns_name
}

output "web_app_wait_command" {
  value = "until curl --max-time 5 http://${aws_lb.alb.dns_name} >/dev/null 2>&1; do echo preparing...; sleep 5; done; echo; echo -e 'Ready!!'"
}
