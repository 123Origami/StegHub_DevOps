data "aws_availability_zones" "available" {
    state = "available"
}

#create VPC

resource "aws_vpc" "main" {

    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

     tags = merge(var.tags, {
    Name = "${var.environment}-vpc"
  })
}

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