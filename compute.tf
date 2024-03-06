resource "aws_lb" "alb" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_launch_template" "nginx" {
  image_id               = var.instance_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = filebase64("${path.module}/ec2.userdata")
}

resource "aws_lb_target_group" "alb_tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_listener_rule" "forward" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }

  condition {
    path_pattern {
      values = ["/", "/*"]
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb_target_group.alb_tg]
}
