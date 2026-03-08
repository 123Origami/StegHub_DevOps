# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2_instance_role"
  
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

  tags = merge(var.tags, {
    Name = "EC2-Instance-Role"
  })
}

# IAM Policy
resource "aws_iam_policy" "policy" {
  name        = "ec2_instance_policy"
  description = "Policy for EC2 instances"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "EC2-Policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach-policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.policy.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "ip" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_instance_role.name
}