variable "workstation_ip" {
  type = string
}

variable "instance_ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}
