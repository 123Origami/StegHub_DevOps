# External ALB
resource "aws_lb" "ext-alb" {
  name               = "ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ext-alb-sg.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(var.tags, {
    Name = "External-ALB"
  })
}

# Target group for Nginx
resource "aws_lb_target_group" "nginx-tgt" {
  name     = "nginx-tgt"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
  }

  tags = merge(var.tags, {
    Name = "nginx-tg"
  })
}

# Listener for external ALB
resource "aws_lb_listener" "nginx-listener" {
  load_balancer_arn = aws_lb.ext-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-tgt.arn
  }
}