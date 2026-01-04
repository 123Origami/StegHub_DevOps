# Provider configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    var.tags,
    {
      Name = format("%s-VPC", var.name)
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = var.preferred_number_of_public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = format("PublicSubnet-%s", count.index)
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = var.preferred_number_of_private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + var.preferred_number_of_public_subnets)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(
    var.tags,
    {
      Name = format("PrivateSubnet-%s", count.index)
    }
  )
}