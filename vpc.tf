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
