variable "alb_sg_id" {
  type = string
}

variable "ec2_sg_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(any)
}

variable "private_subnets" {
  type = list(any)
}

variable "instance_type" {
  type = string
}

variable "mongodb_ip" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}
