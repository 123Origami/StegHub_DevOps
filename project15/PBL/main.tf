# Provider configuration
provider "aws" {
  region = var.region
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Common tags
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-VPC"
  })
}

# 2. Public Subnets (2)
resource "aws_subnet" "public" {
  count  = var.preferred_number_of_public_subnets
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

# 3. Private Subnets for Web Servers (2)
resource "aws_subnet" "private_web" {
  count  = 2
  vpc_id = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-web-subnet-${count.index + 1}"
    Type = "private-web"
  })
}

# 4. Private Subnets for Database (2)
resource "aws_subnet" "private_data" {
  count  = 2
  vpc_id = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-data-subnet-${count.index + 1}"
    Type = "private-data"
  })
}

# 5. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-IGW"
  })
}

# 6. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-NAT-EIP"
  })
}

# 7. NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-NAT-GW"
  })

  depends_on = [aws_internet_gateway.igw]
}

# 8. Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-RT"
  })
}

# 9. Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-RT"
  })
}

# 10. Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_web" {
  count = length(aws_subnet.private_web)

  subnet_id      = aws_subnet.private_web[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data" {
  count = length(aws_subnet.private_data)

  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private.id
}

# 11. Security Group for Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ALB-SG"
  })
}

# 12. Security Group for Web Servers
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH from anywhere (temporary)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Web-SG"
  })
}

# 13. Security Group for Database
resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from web servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Database-SG"
  })
}

# 14. Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("C:/Users/User/terraform_key.pub")  # Replace with your public key path

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-KeyPair"
  })
}

# 15. IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-EC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-EC2-Role"
  })
}

# 16. IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-EC2-Profile"
  role = aws_iam_role.ec2_role.name
}

# Find latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 17. EC2 Instances for Tooling Website (2 instances)
resource "aws_instance" "tooling" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id  # Ubuntu 22.04 in eu-north-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_web[count.index].id
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Tooling Website - Server \$(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-tooling-${count.index + 1}"
  })
}

# 18. EC2 Instances for Wordpress Website (2 instances)
resource "aws_instance" "wordpress" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id  # Ubuntu 22.04 in eu-north-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_web[count.index].id
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>WordPress Website - Server \$(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-wordpress-${count.index + 1}"
  })
}

# 19. Application Load Balancer for Tooling
resource "aws_lb" "tooling_alb" {
  name               = "${var.project_name}-tooling-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Tooling-ALB"
  })
}

# 20. Target Group for Tooling
resource "aws_lb_target_group" "tooling_tg" {
  name     = "${var.project_name}-tooling-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Tooling-TG"
  })
}

# 21. ALB Listener for Tooling
resource "aws_lb_listener" "tooling" {
  load_balancer_arn = aws_lb.tooling_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling_tg.arn
  }
}

# 22. ALB Listener Rule for Tooling
resource "aws_lb_listener_rule" "tooling" {
  listener_arn = aws_lb_listener.tooling.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# 23. Target Group Attachment for Tooling
resource "aws_lb_target_group_attachment" "tooling" {
  count            = length(aws_instance.tooling)
  target_group_arn = aws_lb_target_group.tooling_tg.arn
  target_id        = aws_instance.tooling[count.index].id
  port             = 80
}

# 24. Application Load Balancer for Wordpress (Repeat similar structure)
resource "aws_lb" "wordpress_alb" {
  name               = "${var.project_name}-wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Wordpress-ALB"
  })
}

# 25. Target Group for Wordpress
resource "aws_lb_target_group" "wordpress_tg" {
  name     = "${var.project_name}-wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Wordpress-TG"
  })
}

# 26. ALB Listener for Wordpress
resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}

# 27. Target Group Attachment for Wordpress
resource "aws_lb_target_group_attachment" "wordpress" {
  count            = length(aws_instance.wordpress)
  target_group_arn = aws_lb_target_group.wordpress_tg.arn
  target_id        = aws_instance.wordpress[count.index].id
  port             = 80
}
# 28. RDS Subnet Group
resource "aws_db_subnet_group" "database" {
  name ="pbl-db-subnet-group"
  subnet_ids = aws_subnet.private_data[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-DB-Subnet-Group"
  })
}

# 29. RDS Parameter Group
resource "aws_db_parameter_group" "database" {
  name = "pbl-db-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-DB-Params"
  })
}

# 30. RDS Instance for Tooling
resource "aws_db_instance" "tooling_db" {
  identifier             = "plb-tooling-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  db_name               = "toolingdb"
  username              = "admin"
  password              = "ChangeThisPassword123!"  # Change in production!
  
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  parameter_group_name   = aws_db_parameter_group.database.name
  
  skip_final_snapshot     = true
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Tooling-DB"
  })
}

# 31. RDS Instance for Wordpress
resource "aws_db_instance" "wordpress_db" {
  identifier             = "plb-wordpress-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  db_name               = "wordpressdb"
  username              = "admin"
  password              = "ChangeThisPassword123!"  # Change in production!
  
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  parameter_group_name   = aws_db_parameter_group.database.name
  
  skip_final_snapshot     = true
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Wordpress-DB"
  })
}