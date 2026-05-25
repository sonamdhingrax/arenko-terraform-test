locals {
  network = {
    develop = {
      vpc_cidr           = "10.0.0.0/16"
      availability_zones = ["eu-west-2a", "eu-west-2b"]
      public_subnets     = ["10.0.0.0/24", "10.0.1.0/24"]
      private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
      database_subnets   = ["10.0.6.0/24", "10.0.7.0/24"]
    }

    prod = {
      vpc_cidr           = "10.1.0.0/16"
      availability_zones = ["eu-west-2a", "eu-west-2b"]
      public_subnets     = ["10.1.0.0/24", "10.1.1.0/24"]
      private_subnets    = ["10.1.3.0/24", "10.1.4.0/24"]
      database_subnets   = ["10.1.6.0/24", "10.1.7.0/24"]
    }
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.network[var.environment].vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_nat_gateway" "nat_gateway" {
  vpc_id            = aws_vpc.vpc.id
  availability_mode = "regional"
  depends_on        = [aws_internet_gateway.igw]
}


resource "aws_subnet" "public" {
  count                   = length(local.network[var.environment].public_subnets)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.network[var.environment].public_subnets[count.index]
  availability_zone       = local.network[var.environment].availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = length(local.network[var.environment].private_subnets)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.network[var.environment].private_subnets[count.index]
  availability_zone       = local.network[var.environment].availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "database" {
  count                   = length(local.network[var.environment].database_subnets)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.network[var.environment].database_subnets[count.index]
  availability_zone       = local.network[var.environment].availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-database-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(local.network[var.environment].public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "${var.environment}-private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(local.network[var.environment].private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-database-route-table"
  }
}

resource "aws_route_table_association" "database" {
  count          = length(local.network[var.environment].database_subnets)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.issue_vpc.id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
