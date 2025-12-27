output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_web_subnet_ids" {
  description = "Private web subnet IDs"
  value       = aws_subnet.private_web[*].id
}

output "private_data_subnet_ids" {
  description = "Private data subnet IDs"
  value       = aws_subnet.private_data[*].id
}

output "tooling_alb_dns_name" {
  description = "Tooling ALB DNS name"
  value       = aws_lb.tooling_alb.dns_name
}

output "wordpress_alb_dns_name" {
  description = "WordPress ALB DNS name"
  value       = aws_lb.wordpress_alb.dns_name
}

output "tooling_ec2_public_ips" {
  description = "Tooling EC2 public IPs"
  value       = aws_instance.tooling[*].public_ip
  sensitive   = true
}

output "wordpress_ec2_public_ips" {
  description = "WordPress EC2 public IPs"
  value       = aws_instance.wordpress[*].public_ip
  sensitive   = true
}

output "tooling_db_endpoint" {
  description = "Tooling RDS endpoint"
  value       = aws_db_instance.tooling_db.endpoint
  sensitive   = true
}

output "wordpress_db_endpoint" {
  description = "WordPress RDS endpoint"
  value       = aws_db_instance.wordpress_db.endpoint
  sensitive   = true
}