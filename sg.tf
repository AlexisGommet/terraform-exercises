resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

#resource "aws_security_group_rule" "ssh_ingress" {
#  type              = "ingress"
#  from_port         = 22
#  to_port           = 22
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.ec2_sg.id
#}

#resource "aws_security_group_rule" "alb_sg_egress" {
#  type                     = "egress"
#  from_port                = 80
#  to_port                  = 80
#  protocol                 = "tcp"
#  security_group_id        = aws_security_group.alb_sg.id
#  source_security_group_id = aws_security_group.ec2_sg.id
#}
#
#resource "aws_security_group_rule" "ec2_alb_ingress" {
#  type                     = "ingress"
#  from_port                = 80
#  to_port                  = 80
#  protocol                 = "tcp"
#  security_group_id        = aws_security_group.ec2_sg.id
#  source_security_group_id = aws_security_group.alb_sg.id
#}

resource "aws_security_group_rule" "alb_sg_egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ec2_alb_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ec2_alb_ingress2" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
