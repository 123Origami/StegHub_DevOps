# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-vpc"
  })
}

# Create public subnets
resource "aws_subnet" "public" {
  count = var.preferred_number_of_public_subnets
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(var.tags, {
    Name = format("PublicSubnet-%d", count.index + 1)
    Type = "Public"
  })
}

# Create private subnets
resource "aws_subnet" "private" {
  count = var.preferred_number_of_private_subnets
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + var.preferred_number_of_public_subnets)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  tags = merge(var.tags, {
    Name = format("PrivateSubnet-%d", count.index + 1)
    Type = "Private"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-IG", var.name)
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.ig]

  tags = merge(var.tags, {
    Name = format("%s-NAT-EIP", var.name)
  })
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.ig]

  tags = merge(var.tags, {
    Name = format("%s-NAT", var.name)
  })
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = merge(var.tags, {
    Name = format("%s-Public-RT", var.name)
  })
}

# Public route table associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, {
    Name = format("%s-Private-RT", var.name)
  })
}

# Private route table associations
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}