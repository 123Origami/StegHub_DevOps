# Launch Template for Bastion
resource "aws_launch_template" "bastion" {
  name_prefix   = "bastion-"
  image_id      = var.ami
  instance_type = "t2.micro"
  key_name      = var.keypair
  
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ip.name
  }
  
  user_data = filebase64("${path.module}/bastion.sh")
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "bastion"
    })
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Bastion
resource "aws_autoscaling_group" "bastion-asg" {
  name                = "bastion-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "bastion"
    propagate_at_launch = true
  }
}