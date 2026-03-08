# KMS Key for EFS encryption
resource "aws_kms_key" "efs-kms" {
  description = "KMS key for EFS encryption"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_no}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "efs-kms-key"
  })
}

# EFS File System
resource "aws_efs_file_system" "efs" {
  encrypted  = true
  kms_key_id = aws_kms_key.efs-kms.arn

  tags = merge(var.tags, {
    Name = "shared-efs"
  })
}

# EFS Mount Targets (in private subnets)
resource "aws_efs_mount_target" "efs-mt" {
  count = 2  # Mount in 2 AZs for HA
  
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private[count.index + 2].id  # Use last 2 private subnets
  security_groups = [aws_security_group.datalayer-sg.id]
}

# Access Point for WordPress
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.efs.id

  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = 755
    }
  }

  tags = merge(var.tags, {
    Name = "wordpress-ap"
  })
}

# Access Point for Tooling
resource "aws_efs_access_point" "tooling" {
  file_system_id = aws_efs_file_system.efs.id

  root_directory {
    path = "/tooling"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = 755
    }
  }

  tags = merge(var.tags, {
    Name = "tooling-ap"
  })
}