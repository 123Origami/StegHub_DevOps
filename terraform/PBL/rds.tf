# DB Subnet Group
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private[2].id, aws_subnet.private[3].id]

  tags = merge(var.tags, {
    Name = "rds-subnet-group"
  })
}

# RDS Instance
resource "aws_db_instance" "rds" {
  identifier = "wordpress-db"
  
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  storage_type         = "gp2"
  storage_encrypted    = true
  
  db_name  = "wordpressdb"
  username = var.master-username
  password = var.master-password
  
  vpc_security_group_ids = [aws_security_group.datalayer-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  skip_final_snapshot    = true
  
  tags = merge(var.tags, {
    Name = "wordpress-rds"
  })
}