variable "region" {
  description = "AWS region"
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "172.16.0.0/16"
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  default     = "true"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  default     = "true"
}

variable "enable_classiclink" {
  description = "Enable ClassicLink"
  default     = "false"
}

variable "enable_classiclink_dns_support" {
  description = "Enable ClassicLink DNS Support"
  default     = "false"
}

variable "preferred_number_of_public_subnets" {
  description = "Number of public subnets"
  default     = 2
}

variable "preferred_number_of_private_subnets" {
  description = "Number of private subnets"
  default     = 4
}

variable "project_name" {
  description = "Project name for tagging"
  default     = "PBL"
}

variable "environment" {
  description = "Environment name"
  default     = "dev"
}