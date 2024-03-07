output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}

output "mongodb_sg_id" {
  value = aws_security_group.mongodb_sg.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}
