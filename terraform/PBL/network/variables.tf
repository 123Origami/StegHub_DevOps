variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "preferred_number_of_public_subnets" {
  description = "Number of public subnets"
  type        = number
}

variable "preferred_number_of_private_subnets" {
  description = "Number of private subnets"
  type        = number
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Base name for resources"
  type        = string
  default     = "ACS"
}