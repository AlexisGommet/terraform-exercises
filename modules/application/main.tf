terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_lb" "alb" {
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = false
  internal                   = false
}

resource "aws_launch_template" "app" {
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(data.template_cloudinit_config.config.rendered)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name  = "FrontendApp"
      Owner = "CloudAcademy"
    }
  }

  depends_on = [
    aws_lb.alb
  ]
}

resource "aws_lb_target_group" "front_tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 6
    timeout             = 5
  }
}

resource "aws_lb_target_group" "back_tg" {
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/ok"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 6
    timeout             = 5
  }
}

resource "aws_lb_listener" "front_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_tg.arn
  }
}

resource "aws_lb_listener" "back_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_tg.arn
  }
}

resource "aws_lb_listener_rule" "frontend_rule1" {
  listener_arn = aws_lb_listener.front_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_tg.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_listener_rule" "api_rule1" {
  listener_arn = aws_lb_listener.back_listener.arn
  priority     = 10

  condition {
    path_pattern {
      values = [
        "/languages",
        "/languages/*",
        "/languages/*/*",
        "/ok"
      ]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_tg.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = var.private_subnets
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.front_tg.arn, aws_lb_target_group.back_tg.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}

data "aws_instances" "application" {
  instance_tags = {
    Name  = "FrontendApp"
    Owner = "CloudAcademy"
  }

  instance_state_names = ["pending", "running"]

  depends_on = [
    aws_autoscaling_group.asg
  ]
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  #userdata
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
        #! /bin/bash
    apt-get -y update
    apt-get -y install nginx
    apt-get -y install jq

    ALB_DNS=${aws_lb.alb.dns_name}
    MONGODB_PRIVATEIP=${var.mongodb_ip}

    mkdir -p /tmp/cloudacademy-app
    cd /tmp/cloudacademy-app

    echo ===========================
    echo FRONTEND - download latest release and install...
    mkdir -p ./voteapp-frontend-react-2023
    pushd ./voteapp-frontend-react-2023
    curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2023/releases/latest | jq -r '.assets[0].browser_download_url' | xargs curl -OL
    INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2023/releases/latest | jq -r '.assets[0].name')
    tar -xvzf $INSTALL_FILENAME
    rm -rf /var/www/html
    cp -R build /var/www/html
    cat > /var/www/html/env-config.js << EOFF
    window._env_ = {REACT_APP_APIHOSTPORT: "$ALB_DNS"}
    EOFF
    popd

    echo ===========================
    echo API - download latest release, install, and start...
    mkdir -p ./voteapp-api-go
    pushd ./voteapp-api-go
    curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url' | xargs curl -OL
    INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .name')
    tar -xvzf $INSTALL_FILENAME
    #start the API up...
    MONGO_CONN_STR=mongodb://$MONGODB_PRIVATEIP:27017/langdb ./api &
    popd

    systemctl restart nginx
    systemctl status nginx
    echo fin v1.00!

    EOF
  }
}
