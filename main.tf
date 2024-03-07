terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "application" {
  source = "./modules/application"

  instance_type   = var.instance_type
  alb_sg_id       = module.security.alb_sg_id
  ec2_sg_id       = module.security.ec2_sg_id
  vpc_id          = module.network.vpc_id
  public_subnets  = [for subnet in module.network.public_subnets : subnet.id]
  private_subnets = [for subnet in module.network.private_subnets : subnet.id]
  mongodb_ip      = module.storage.private_ip
  ami_id          = data.aws_ami.ubuntu.id
  key_name        = var.key_name

  depends_on = [
    module.security,
    module.network,
    module.storage
  ]
}

module "network" {
  source = "./modules/network"

  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"

  vpc_id = module.network.vpc_id

  depends_on = [
    module.network
  ]
}

module "storage" {
  source = "./modules/storage"

  instance_type = var.instance_type
  subnet_id     = module.network.private_subnets[0].id
  sg_id         = module.security.mongodb_sg_id
  key_name      = var.key_name

  depends_on = [
    module.network,
    module.security
  ]
}

module "bastion" {
  source = "./modules/bastion"

  instance_type = var.instance_type
  subnet_id     = module.network.public_subnets[0].id
  sg_id         = module.security.bastion_sg_id
  key_name      = var.key_name

  depends_on = [
    module.network,
    module.security
  ]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"]
}
