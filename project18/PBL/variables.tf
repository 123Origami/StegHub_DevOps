variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

variable "preferred_number_of_public_subnets" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "preferred_number_of_private_subnets" {
  description = "Number of private subnets"
  type        = number
  default     = 4
}

variable "ami" {
  description = "AMI ID for instances"
  type        = string
}

variable "keypair" {
  description = "Key pair name"
  type        = string
}

variable "master-username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "master-password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Managed-By = "Terraform"
  }
}




variable "ami_map" {
  description = "Map of AMI IDs by region"
  type        = map(string)
  default = {
    us-east-1 = "ami-0b0af3577fe5e3532"  # Amazon Linux 2 in us-east-1
    us-east-2 = "ami-0cb91c7de36ede2c0"  # Amazon Linux 2 in us-east-2
    eu-west-1 = "ami-0e4e4b4f4e4e4e4e4"  # Amazon Linux 2 in eu-west-1
  }
}

variable "instance_types" {
  description = "Instance types for different environments"
  type        = map(string)
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.medium"
  }
}
/* variable "region" {
    description = "Aws region to deploy resources"
    type = string
    default = "eu-north-1"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "172.16.0.0/16"

}

variable "enable_dns_support" {
    description = "Enable DNS Support in VPC"
    type = bool
    default = true
}

variable "enable_dns_hostnames" {
    description = "Enable DNS hostnames in VPC"
    type = bool
    default = true
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.16.0.0/24", "172.16.1.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]  # Note: Different AZs for HA
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "learning"
}

variable "preferred_number_of_public_subnets" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "preferred_number_of_private_subnets" {
  description = "Number of private subnets"
  type        = number
  default     = 4
}


variable "ami" {
  description = "AMI ID for instances"
  type        = string
}

variable "keypair" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "account_no" {
  description = "AWS account number"
  type        = string
}

variable "master-username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "master-password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "Learning"
    Managed-By  = "Terraform"
  }
}

variable "name" {
  description = "Base name for resources"
  type        = string
  default     = "ACS"
} */