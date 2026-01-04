variable "region" {
  type        = string
  description = "The region to deploy resources"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "The VPC CIDR"
  default     = "172.16.0.0/16"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_classiclink" {
  type    = bool
  default = false
}

variable "enable_classiclink_dns_support" {
  type    = bool
  default = false
}

variable "preferred_number_of_public_subnets" {
  type        = number
  description = "Number of public subnets"
  default     = 2
}

variable "preferred_number_of_private_subnets" {
  type        = number
  description = "Number of private subnets"
  default     = 4
}

variable "name" {
  type    = string
  default = "ACS"
}

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

variable "ami" {
  type        = string
  description = "AMI ID for the launch template"
}

variable "keypair" {
  type        = string
  description = "key pair for the instances"
}

variable "account_no" {
  type        = number
  description = "the account number"
}

variable "master-username" {
  type        = string
  description = "RDS admin username"
}

variable "master-password" {
  type        = string
  description = "RDS master password"
  sensitive   = true
}

variable "db-username" {
  type        = string
  description = "Database username"
}

variable "db-password" {
  type        = string
  description = "Database password"
  sensitive   = true
}