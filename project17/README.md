# **Terraform Advanced Concepts & Infrastructure Refactoring Project**

## **📋 Project Overview**
This project focuses on enhancing Terraform infrastructure code by implementing advanced AWS concepts. We will transition from local state management to remote backend using S3 with DynamoDB locking, refactor code using dynamic blocks and modules, and implement best practices for production-grade Terraform configurations.

---

## ** Project Objectives**

### **Core Objectives:**
1. **Implement Remote State Management** with S3 backend and DynamoDB locking
2. **Refactor Security Groups** using dynamic blocks
3. **Implement AMI Selection** using maps and lookup functions
4. **Reorganize Infrastructure** using Terraform modules
5. **Apply Conditional Expressions** for resource management
6. **Implement Environment Isolation** strategies

### **Learning Outcomes:**
- Understand Terraform backends and state management
- Master Terraform code organization and modularization
- Learn advanced Terraform language features
- Implement team collaboration workflows
- Apply production-ready infrastructure patterns

---

## ** Architecture Components**

### **1. Remote Backend Infrastructure**
```
┌─────────────────────────────────────────────────┐
│                 AWS Environment                  │
├─────────────────────────────────────────────────┤
│  ┌────────────┐     ┌─────────────────────┐     │
│  │   S3 Bucket│◄────│ Terraform State File│     │
│  │  (Backend) │     │   (Versioned)       │     │
│  └────────────┘     └─────────────────────┘     │
│          │                                       │
│          ▼                                       │
│  ┌────────────┐     ┌─────────────────────┐     │
│  │ DynamoDB   │◄────│ State Locking       │     │
│  │   Table    │     │   Mechanism         │     │
│  └────────────┘     └─────────────────────┘     │
└─────────────────────────────────────────────────┘
```

### **2. Modular Structure**
```
PBL/
├── modules/                    # Reusable infrastructure components
│   ├── network/               # VPC, Subnets, Route Tables
│   ├── security/              # Security Groups, NACLs
│   ├── compute/               # EC2 Instances, Launch Templates
│   ├── autoscaling/           # ASG, Scaling Policies
│   ├── ALB/                   # Application Load Balancer
│   ├── RDS/                   # Database Resources
│   └── EFS/                   # Elastic File System
├── environments/              # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
└── root_module/               # Main configuration
```

---

## ** Implementation Guide**

### **Phase 1: Setting Up Remote Backend**

#### **Step 1: Create Backend Resources**
Create `backend.tf`:
```hcl
# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "dev-terraform-bucket-${random_id.suffix.hex}" # Unique name
  force_destroy = false
  
  # Versioning for state file history
  versioning {
    enabled = true
  }
  
  # Server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Lifecycle rules
  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 90
    }
  }
  
  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### **Step 2: Create DynamoDB Table for Locking**
```hcl
# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name        = "Terraform State Locking"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

#### **Step 3: Configure Backend**
Create `backend.hcl`:
```hcl
# Backend configuration (to be used with terraform init -backend-config)
bucket         = "dev-terraform-bucket-abc123"
key            = "environments/${terraform.workspace}/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks-dev"
encrypt        = true
```

Update main `terraform` block:
```hcl
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
    # Parameters will be passed via -backend-config
    # or through backend.hcl file
  }
}
```

#### **Step 4: Initialize Remote Backend**
```bash
# Generate random suffix for bucket name
terraform apply -target=random_id.suffix

# Apply backend resources
terraform apply -target=aws_s3_bucket.terraform_state \
                -target=aws_dynamodb_table.terraform_locks

# Initialize with remote backend
terraform init -reconfigure \
  -backend-config=backend.hcl \
  -backend-config="bucket=dev-terraform-bucket-$(terraform output -raw bucket_suffix)"
```

---

### **Phase 2: Code Refactoring**

#### **Refactor 1: Security Groups with Dynamic Blocks**
Create `modules/security/main.tf`:
```hcl
# Dynamic Security Group Module
resource "aws_security_group" "main" {
  name        = "${var.name}-sg"
  description = var.description
  vpc_id      = var.vpc_id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
    }
  }
  
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}
```

Create `modules/security/variables.tf`:
```hcl
variable "name" {
  description = "Security group name"
  type        = string
}

variable "description" {
  description = "Security group description"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

#### **Refactor 2: EC2 AMI Selection with Maps**
Create `modules/compute/variables.tf`:
```hcl
variable "region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_map" {
  description = "AMI IDs per region"
  type        = map(string)
  default = {
    us-east-1 = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-0d729a60"
    ap-southeast-1 = "ami-0b4f379183e5706b9"
  }
}

variable "custom_ami_id" {
  description = "Custom AMI ID (overrides ami_map)"
  type        = string
  default     = null
}
```

Create `modules/compute/main.tf`:
```hcl
# Lookup AMI based on region or use custom AMI
locals {
  ami_id = var.custom_ami_id != null ? var.custom_ami_id : lookup(
    var.ami_map,
    var.region,
    var.ami_map["us-east-1"]  # Default fallback
  )
}

resource "aws_instance" "main" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }
  
  user_data = var.user_data
  
  tags = merge(var.tags, {
    Name = var.name
  })
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,  # AMI updates handled separately
    ]
  }
}
```

#### **Refactor 3: Conditional Resource Creation**
```hcl
# Conditional RDS Read Replica
variable "create_read_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = false
}

resource "aws_db_instance" "primary" {
  identifier     = "${var.environment}-db-primary"
  engine         = "mysql"
  instance_class = var.db_instance_class
  
  # ... other configurations
}

resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0
  
  identifier        = "${var.environment}-db-replica"
  replicate_source_db = aws_db_instance.primary.id
  instance_class    = var.db_instance_class
  
  # Read replicas cannot have storage specified
  skip_final_snapshot = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-db-replica"
  })
}
```

---

### **Phase 3: Module Implementation**

#### **Project Structure:**
```
project/
├── main.tf                    # Root module
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── terraform.tfvars           # Variable values
├── backend.tf                 # Backend configuration
├── providers.tf               # Provider configuration
├── versions.tf                # Version constraints
├── locals.tf                  # Local values
├── data.tf                    # Data sources
│
├── modules/                   # Reusable modules
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── security/
│   ├── compute/
│   ├── database/
│   ├── storage/
│   └── loadbalancer/
│
├── environments/              # Environment-specific configs
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── backend.hcl
│   ├── staging/
│   └── prod/
│
└── scripts/                   # Helper scripts
    ├── setup-backend.sh
    ├── terraform-workspace.sh
    └── validate.sh
```

#### **Example Module Usage:**
In `main.tf`:
```hcl
module "network" {
  source = "./modules/network"
  
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.availability_zones
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = local.common_tags
}

module "security" {
  source = "./modules/security"
  
  vpc_id      = module.network.vpc_id
  environment = var.environment
  
  # Web security group
  web_sg_rules = {
    ingress = [
      {
        description = "HTTP from ALB"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = [module.loadbalancer.alb_security_group_id]
      },
      {
        description = "HTTPS from ALB"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        security_groups = [module.loadbalancer.alb_security_group_id]
      }
    ]
  }
  
  tags = local.common_tags
}
```

---

### **Phase 4: Environment Isolation**

#### **Option 1: Workspaces**
```bash
# Create workspaces for different environments
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between workspaces
terraform workspace select dev

# Workspace-specific variables in terraform.tfvars
dev = {
  instance_type = "t3.micro"
  instance_count = 2
}

prod = {
  instance_type = "t3.large"
  instance_count = 4
}

# Use in configuration
resource "aws_instance" "web" {
  count = lookup(var.environment_config[terraform.workspace], "instance_count", 1)
  instance_type = lookup(var.environment_config[terraform.workspace], "instance_type", "t3.micro")
}
```

#### **Option 2: Directory-based Separation**
```
environments/
├── dev/
│   ├── main.tf          # Dev-specific overrides
│   ├── variables.tf
│   └── terraform.tfvars
├── staging/
└── prod/
```

---

## **🔧 Advanced Features Implementation**

### **1. Dynamic Blocks for Route Tables**
```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-private-rt"
  })
}
```

### **2. Complex Map Structures for Configuration**
```hcl
variable "instance_configs" {
  type = map(object({
    instance_type = string
    volume_size   = number
    min_size      = number
    max_size      = number
    desired_size  = number
  }))
  default = {
    web = {
      instance_type = "t3.micro"
      volume_size   = 20
      min_size      = 2
      max_size      = 4
      desired_size  = 2
    }
    app = {
      instance_type = "t3.small"
      volume_size   = 30
      min_size      = 2
      max_size      = 6
      desired_size  = 3
    }
  }
}
```

### **3. For-Each with Maps**
```hcl
resource "aws_security_group_rule" "custom_rules" {
  for_each = {
    for idx, rule in var.custom_rules : 
    "${rule.type}_${rule.from_port}_${rule.to_port}" => rule
  }
  
  security_group_id = aws_security_group.main.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}
```

---

## ** Testing and Validation**

### **Validation Commands:**
```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Check plan
terraform plan -var-file="environments/dev/terraform.tfvars"

# Show current workspace
terraform workspace show

# State operations
terraform state list
terraform state show aws_vpc.main

# Graph visualization
terraform graph | dot -Tsvg > graph.svg
```

### **Pre-commit Hooks:**
Create `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
```

---

## **🚀 Deployment Workflow**

### **Development Workflow:**
```bash
# 1. Clone repository
git clone <repo-url>
cd terraform-project

# 2. Set up backend (first time only)
./scripts/setup-backend.sh

# 3. Initialize workspace
terraform init
terraform workspace new dev
terraform workspace select dev

# 4. Plan changes
terraform plan -out=tfplan \
  -var-file="environments/dev/terraform.tfvars"

# 5. Apply changes
terraform apply tfplan

# 6. Review outputs
terraform output -json
```

### **CI/CD Pipeline Example (GitHub Actions):**
```yaml
name: Terraform CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Init
      run: terraform init -backend-config="environments/prod/backend.hcl"
    
    - name: Terraplan Format
      run: terraform fmt -check
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      run: terraform plan -out=tfplan -var-file="environments/prod/terraform.tfvars"
    
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve tfplan
```

---

## **🔐 Security Best Practices**

### **1. Secret Management:**
```hcl
# Use AWS Secrets Manager or Parameter Store
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "${var.environment}/database/password"
}

resource "aws_db_instance" "database" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
  # ... other config
}
```

### **2. IAM Roles and Policies:**
```hcl
# Least privilege principle
resource "aws_iam_role" "ec2_role" {
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
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

### **3. Encryption:**
```hcl
# Enable encryption everywhere
resource "aws_ebs_volume" "data" {
  encrypted = true
  kms_key_id = aws_kms_key.ebs.arn
}

resource "aws_rds_cluster" "aurora" {
  storage_encrypted = true
  kms_key_id = aws_kms_key.rds.arn
}
```

---

## ** Monitoring and Maintenance**

### **1. State File Management:**
```bash
# List state file versions
aws s3api list-object-versions \
  --bucket dev-terraform-bucket \
  --prefix environments/dev/

# Recover previous state
terraform state pull > terraform.tfstate.backup
terraform state push terraform.tfstate.backup
```

### **2. Cost Management Tags:**
```hcl
locals {
  cost_center_tags = {
    CostCenter   = "IT-1234"
    Project      = var.project_name
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Owner        = var.owner_email
    CreationDate = timestamp()
  }
}
```

### **3. Drift Detection:**
```bash
# Check for configuration drift
terraform plan -detailed-exitcode

# Refresh state
terraform refresh

# Import existing resources
terraform import aws_instance.web i-1234567890abcdef0
```

---

## **🚨 Troubleshooting Guide**

### **Common Issues and Solutions:**

#### **Issue 1: State Locking Problems**
```bash
# Force unlock (use with caution!)
terraform force-unlock LOCK_ID

# Check DynamoDB lock
aws dynamodb scan --table-name terraform-locks
```

#### **Issue 2: Module Source Errors**
```bash
# Update module sources
terraform get -update

# Clean module cache
rm -rf .terraform/modules
terraform init
```

#### **Issue 3: Provider Version Conflicts**
```hcl
# Pin provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Allows 4.x but not 5.0
    }
  }
}
```

#### **Issue 4: Invalid AMI in Region**
```hcl
# Use data source to find latest AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

---

## **📚 Best Practices Summary**

### **Code Organization:**
1. **Modular Design**: Break down infrastructure into logical modules
2. **Directory Structure**: Use consistent, predictable layouts
3. **Environment Separation**: Use workspaces or directories for different environments
4. **State Isolation**: Separate state files per environment
5. **Version Control**: Keep all Terraform code in version control

### **Security:**
1. **Remote State**: Never store state files locally in production
2. **Encryption**: Enable encryption for all resources
3. **Least Privilege**: Apply minimal necessary permissions
4. **Secret Management**: Never hardcode secrets in Terraform files
5. **Access Control**: Use IAM roles and policies extensively

### **Operational Excellence:**
1. **Tagging Strategy**: Implement consistent tagging for cost management
2. **Backup Strategy**: Version S3 state files and enable DynamoDB PITR
3. **Monitoring**: Implement CloudTrail logging for Terraform operations
4. **Documentation**: Maintain README files for all modules
5. **Testing**: Implement validation and plan review processes

### **Collaboration:**
1. **State Locking**: Prevent concurrent modifications
2. **Code Reviews**: Require reviews for Terraform changes
3. **CI/CD Integration**: Automate testing and deployment
4. **Workspace Management**: Establish clear workspace usage guidelines
5. **Change Management**: Implement approval workflows for production changes

---

## ** Submission Requirements**

### **Required Deliverables:**
1.  Complete Terraform configuration with modules
2.  S3 backend with DynamoDB locking
3.  Refactored security groups using dynamic blocks
4.  AMI selection using maps and lookup
5.  Environment isolation implementation
6.  Proper output variables
7.  Documentation (this README)

### **File Structure Checklist:**
```
[ ] backend.tf
[ ] providers.tf
[ ] versions.tf
[ ] variables.tf
[ ] outputs.tf
[ ] main.tf
[ ] terraform.tfvars
[ ] modules/network/
[ ] modules/security/
[ ] modules/compute/
[ ] modules/database/
[ ] modules/loadbalancer/
[ ] environments/dev/
[ ] environments/prod/
[ ] README.md
[ ] .gitignore
[ ] .pre-commit-config.yaml
```

### **Validation Commands to Run:**
```bash
terraform validate
terraform fmt -check -diff
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform workspace list
```

---



## ** Important Notes**

1. **Bucket Names Must Be Globally Unique**: Always use random suffixes
2. **State File Contains Secrets**: Always enable encryption
3. **Lock Before Operations**: Terraform will automatically handle locking
4. **Never Manually Modify State Files**: Use Terraform commands only
5. **Backup State Files**: Enable versioning on S3 buckets
6. **Test in Non-Production First**: Always validate changes in dev/staging

