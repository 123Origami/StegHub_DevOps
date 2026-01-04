region = "us-east-1"
vpc_cidr = "172.16.0.0/16"
enable_dns_support = true
enable_dns_hostnames = true
enable_classiclink = false
enable_classiclink_dns_support = false
preferred_number_of_public_subnets = 2
preferred_number_of_private_subnets = 4
name = "ACS"

# Update these with your values
ami = "ami-0b0af3577fe5e3532"  # Ubuntu 20.04 in us-east-1
keypair = "devops"
account_no = "123456789012"  # Your AWS account number

db-username = "david"
db-password = "devopspbl"

tags = {
  Environment      = "production"
  Owner-Email      = "infradev-segun@darey.io"
  Managed-By       = "Terraform"
  Billing-Account  = "1234567890"
}