variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "security_groups" {
  description = "Security groups configuration"
  type = map(object({
    description = string
    ingress_rules = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string))
      security_groups = optional(list(string))
    }))
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}