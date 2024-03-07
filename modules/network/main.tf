terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0), 1, count.index)
  availability_zone = element(var.availability_zones, count.index)
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1), 1, count.index)
  availability_zone = element(var.availability_zones, count.index)
}


resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat.id
  depends_on    = [aws_internet_gateway.gateway]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = 2
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}
