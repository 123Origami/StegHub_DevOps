# Configure AWS Provider
provider "aws" {
  region = var.region
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Network Module
module "network" {
  source = "./modules/network"
  
  environment                       = var.environment
  vpc_cidr                          = var.vpc_cidr
  preferred_number_of_public_subnets  = var.preferred_number_of_public_subnets
  preferred_number_of_private_subnets = var.preferred_number_of_private_subnets
  tags                               = var.tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  vpc_id = module.network.vpc_id
  
  security_groups = {
    "ext-alb-sg" = {
      description = "External ALB Security Group"
      ingress_rules = [
        {
          description = "HTTP from anywhere"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "HTTPS from anywhere"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    
    "bastion-sg" = {
      description = "Bastion Security Group"
      ingress_rules = [
        {
          description = "SSH from anywhere"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    
    "nginx-sg" = {
      description = "Nginx Security Group"
      ingress_rules = [
        {
          description     = "HTTPS from external ALB"
          from_port       = 443
          to_port         = 443
          protocol        = "tcp"
          security_groups = ["ext-alb-sg"]
        },
        {
          description     = "SSH from bastion"
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          security_groups = ["bastion-sg"]
        }
      ]
    }
    
    "int-alb-sg" = {
      description = "Internal ALB Security Group"
      ingress_rules = [
        {
          description     = "HTTPS from nginx"
          from_port       = 443
          to_port         = 443
          protocol        = "tcp"
          security_groups = ["nginx-sg"]
        }
      ]
    }
    
    "webserver-sg" = {
      description = "Webserver Security Group"
      ingress_rules = [
        {
          description     = "HTTPS from internal ALB"
          from_port       = 443
          to_port         = 443
          protocol        = "tcp"
          security_groups = ["int-alb-sg"]
        },
        {
          description     = "SSH from bastion"
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          security_groups = ["bastion-sg"]
        }
      ]
    }
    
    "datalayer-sg" = {
      description = "Datalayer Security Group"
      ingress_rules = [
        {
          description     = "NFS from webservers"
          from_port       = 2049
          to_port         = 2049
          protocol        = "tcp"
          security_groups = ["webserver-sg"]
        },
        {
          description     = "MySQL from bastion"
          from_port       = 3306
          to_port         = 3306
          protocol        = "tcp"
          security_groups = ["bastion-sg"]
        },
        {
          description     = "MySQL from webservers"
          from_port       = 3306
          to_port         = 3306
          protocol        = "tcp"
          security_groups = ["webserver-sg"]
        }
      ]
    }
  }
  
  tags = var.tags
}




/* provider "aws" {
    region = var.region
}
 */
# Create VPC
/* 
resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = var.enable_dns_support
    enable_dns_hostnames = var.enable_dns_hostnames
    
    tags = {
        Name = "${var.environment}-vpc"
        Environment = var.environment
    }
}


# Create a public subnet using loops

resource "aws_subnet1" "public" {
    count = length(var.public_subnet_cidrs) #creates loop
    vpc_id = aws_vpc.main.id
    cidr_block =var.public_subnet_cidrs[count.index]
    map_public_ip_on_launch = true
    availability_zone = var.availability_zones[count.index]
    tags = {
        Name        = "${var.environment}-public-subnet-${count.index + 1}"
        Environment = var.environment
        Type        = "Public"
  }

}  */



#Create public subnets1

/* resource "aws_subnet" "public1"{
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.0.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "eu-north-1"
}
#Create public subnets2
resource "aws_subnet" "public2"{
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.1.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "eu-north-1"
} */