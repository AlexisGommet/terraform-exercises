terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "mongo" {
  ami                    = "ami-02868af3c3df4b3aa"
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]

  root_block_device {
    volume_size = 10
    encrypted   = true
  }

  user_data = filebase64("${path.module}/install.sh")
}
