output "alb_dns_name" {
  value = aws_lb.ext-alb.dns_name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.nginx-tgt.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "bastion_asg_name" {
  value = aws_autoscaling_group.bastion-asg.name
}

output "nginx_asg_name" {
  value = aws_autoscaling_group.nginx-asg.name
}

output "wordpress_asg_name" {
  value = aws_autoscaling_group.wordpress-asg.name
}

output "tooling_asg_name" {
  value = aws_autoscaling_group.tooling-asg.name
}

output "rds_endpoint" {
  value = aws_db_instance.ACS-rds.endpoint
}

output "efs_id" {
  value = aws_efs_file_system.ACS-efs.id
}
