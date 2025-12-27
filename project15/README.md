# **AWS Infrastructure Automation with Terraform - Complete Project Guide**

## **📋 Project Overview**
This project automates the deployment of AWS infrastructure for two websites using Terraform (Infrastructure as Code). The setup includes VPC, subnets, security groups, EC2 instances, load balancers, and RDS databases following AWS best practices.

## **🎯 Project Architecture**
```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS eu-north-1                        │
├─────────────────────────────────────────────────────────────────┤
│                         VPC (172.16.0.0/16)                     │
│                                                                 │
│  ┌─────────────┐          ┌─────────────┐        ┌──────────┐  │
│  │ Public      │          │ Private Web │        │ Private  │  │
│  │ Subnets     │◄──IGW────┤ Subnets     │◄─NAT───┤ Data     │  │
│  │ (AZ1, AZ2)  │          │ (AZ1, AZ2)  │        │ Subnets  │  │
│  │             │          │             │        │ (AZ1,AZ2)│  │
│  └──────┬──────┘          └──────┬──────┘        └─────┬────┘  │
│         │                        │                     │       │
│  ┌──────▼──────┐        ┌────────▼────────┐     ┌──────▼──────┐│
│  │ ALB         │        │ EC2 Instances   │     │ RDS         ││
│  │ (Tooling)   ├────────► (Tooling x2)    ├─────► MySQL      ││
│  └─────────────┘        └─────────────────┘     │ (Tooling)  ││
│  ┌─────────────┐        ┌─────────────────┐     └────────────┘│
│  │ ALB         │        │ EC2 Instances   │     ┌────────────┐│
│  │ (WordPress) ├────────► (WordPress x2)  ├─────► MySQL      ││
│  └─────────────┘        └─────────────────┘     │ (WordPress)││
│                                                  └────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## **🛠️ Prerequisites**

### **1. AWS Account Setup**
- Create IAM user with programmatic access
- Attach `AdministratorAccess` policy
- Save Access Key ID and Secret Access Key
- Configure AWS CLI: `aws configure`

### **2. Local Development Environment**
- **OS**: Windows 10/11, macOS, or Linux
- **VS Code**: With Terraform extension
- **Git Bash** (Windows) or Terminal (macOS/Linux)
- **Terraform CLI** (v1.14.3+)
- **AWS CLI** (v2.13.0+)
- **Python 3.11+** with boto3 library

### **3. Required Installations**
```bash
# Windows (Git Bash)
choco install terraform awscli git python -y

# macOS
brew install terraform awscli git python

# Linux (Ubuntu)
sudo apt-get update
sudo apt-get install terraform awscli git python3-pip
```

## **📁 Project Structure**
```
PBL/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variable declarations
├── terraform.tfvars        # Variable values (gitignored)
├── outputs.tf              # Output values
├── terraform_key.pub       # SSH public key
├── .terraform/             # Terraform plugins (auto-generated)
├── terraform.tfstate       # State file (auto-generated)
└── README.md               # This file
```

## 📁 Project Files

| File | Purpose | Status |
|------|---------|--------|
| [main.tf](main.tf) | Main infrastructure configuration | ✅ Complete |
| [variables.tf](variables.tf) | Input variable declarations | ✅ Complete |
| [outputs.tf](outputs.tf) | Output values from deployment | ✅ Complete |
| terraform.tfvars | Variable values (sensitive) | 🔒 Private |
| [.gitignore](.gitignore) | Git ignore rules | ✅ Complete |

## 🔧 Implementation Details

For the complete Terraform code, please examine:

### **Core Configuration**
- **[main.tf](main.tf)** - Contains all AWS resource definitions including:
  - VPC, subnets, and networking components
  - Security groups and NACLs
  - EC2 instances with user data
  - Application Load Balancers
  - RDS MySQL databases
  - IAM roles and policies

### **Input Variables**
- **[variables.tf](variables.tf)** - Declares all input variables with:
  - Descriptions and default values
  - Type constraints and validation
  - Environment-specific configurations

### **Output Values**
- **[outputs.tf](outputs.tf)** - Defines outputs for:
  - ALB DNS names (website URLs)
  - EC2 instance information
  - Database connection details
  - Network configuration

## **🚀 Deployment Steps**

### **Phase 1: Initial Setup**
```bash
# 1. Clone or create project directory
mkdir PBL && cd PBL

# 2. Create SSH key for EC2 instances
ssh-keygen -t rsa -b 2048 -f terraform_key -N ""

# 3. Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, eu-north-1, json
```

### **Phase 2: Create Configuration Files**

#### **`variables.tf`**
```hcl
variable "region" {
  description = "AWS region"
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "172.16.0.0/16"
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  default     = "true"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  default     = "true"
}

variable "project_name" {
  description = "Project name for tagging"
  default     = "PBL"
}

variable "environment" {
  description = "Environment name"
  default     = "dev"
}
```

#### **`terraform.tfvars`**
```hcl
region = "eu-north-1"
vpc_cidr = "172.16.0.0/16"
enable_dns_support = "true"
enable_dns_hostnames = "true"
project_name = "PBL"
environment = "dev"
```

#### **`main.tf`** (Complete infrastructure - see full code in repository)

### **Phase 3: Initialize and Deploy**
```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan

# 4. Apply infrastructure
terraform apply

# 5. Verify deployment
terraform output
```

## **🏗️ Infrastructure Components**

### **1. Networking Layer**
- **VPC**: 172.16.0.0/16 with DNS support
- **Public Subnets**: 2 subnets across 2 AZs with internet access
- **Private Web Subnets**: 2 subnets for EC2 instances
- **Private Data Subnets**: 2 subnets for RDS databases
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: For private subnet outbound internet
- **Route Tables**: Public and private routing

### **2. Security Layer**
- **ALB Security Group**: Allows HTTP/HTTPS from internet
- **Web Security Group**: Allows traffic from ALB and SSH (temporary)
- **Database Security Group**: Allows MySQL from web servers only

### **3. Compute Layer**
- **EC2 Instances**: 4 instances (2 for Tooling, 2 for WordPress)
- **AMI**: Ubuntu 22.04 LTS
- **Instance Type**: t3.micro
- **User Data**: Auto-installs Nginx with custom homepage

### **4. Load Balancing**
- **Application Load Balancers**: 2 ALBs (Tooling & WordPress)
- **Target Groups**: Health-checked endpoints
- **Listeners**: HTTP port 80

### **5. Database Layer**
- **RDS MySQL**: 2 instances (Tooling & WordPress databases)
- **Instance Type**: db.t3.micro
- **Storage**: 20GB GP2 encrypted
- **Subnet Group**: Across 2 private data subnets

## **🔧 Configuration Details**

### **SSH Key Management**
```hcl
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("terraform_key.pub")
}
```

### **Dynamic AMI Selection**
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

### **Auto-Scaling User Data**
```hcl
user_data_base64 = base64encode(<<-EOF
  #!/bin/bash
  apt-get update
  apt-get install -y nginx
  systemctl start nginx
  systemctl enable nginx
  echo "<h1>Tooling Website - Server $(hostname)</h1>" > /var/www/html/index.html
EOF
)
```

## **📊 Output Values**
After deployment, Terraform outputs:
- VPC ID and subnet IDs
- ALB DNS names (website URLs)
- EC2 instance public IPs
- RDS database endpoints

## **🔍 Testing & Verification**

### **1. Verify Infrastructure**
```bash
# Check all resources
terraform state list

# Test website access
curl $(terraform output tooling_alb_dns_name | tr -d '"')
curl $(terraform output wordpress_alb_dns_name | tr -d '"')

# Check AWS Console
# - VPC: Verify subnets and route tables
# - EC2: Verify instances running
# - RDS: Verify databases available
# - ALB: Verify target groups healthy
```

### **2. Connectivity Tests**
```bash
# SSH to EC2 instances (if key configured)
ssh -i terraform_key ubuntu@$(terraform output tooling_ec2_public_ips | jq -r '.[0]')

# Test database connectivity
mysql -h $(terraform output tooling_db_endpoint | tr -d '"') -u admin -p
```

## **💰 Cost Estimation**
| Resource | Quantity | Monthly Cost (approx) |
|----------|----------|----------------------|
| EC2 t3.micro | 4 | $30 |
| RDS db.t3.micro | 2 | $30 |
| ALB | 2 | $20 |
| NAT Gateway | 1 | $35 |
| EBS Storage | 80GB | $10 |
| **Total** | | **$125/month** |

**Note**: Destroy infrastructure when not in use to avoid charges.

## **⚠️ Troubleshooting Guide**

### **Common Issues & Solutions**

#### **1. "Invalid AMI ID" Error**
```bash
# Find correct AMI for your region
aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --region eu-north-1
```

#### **2. SSH Key Encoding Issues**
```bash
# Generate clean key
ssh-keygen -t rsa -b 2048 -f terraform_key -N ""

# Verify format
cat terraform_key.pub  # Should be one line starting with "ssh-rsa"
```

#### **3. RDS Naming Errors**
- Names must be lowercase
- First character must be letter
- Use hyphens, not underscores
```hcl
name = "${lower(var.project_name)}-db-subnet-group"
```

#### **4. State Lock Issues**
```bash
# If terraform apply hangs
rm -f terraform.tfstate.lock.info
terraform force-unlock <LOCK_ID>
```

### **Debug Commands**
```bash
# Show detailed plan
terraform plan -detailed-exitcode

# Refresh state
terraform refresh

# Show resource attributes
terraform state show aws_vpc.main

# List all outputs
terraform output -json
```

## **🧹 Cleanup & Destruction**
```bash
# 1. Review what will be destroyed
terraform plan -destroy

# 2. Destroy all resources
terraform destroy

# 3. Verify cleanup
aws ec2 describe-instances --region eu-north-1
aws rds describe-db-instances --region eu-north-1
```

## **🔒 Security Best Practices**

### **Production Recommendations**
1. **Use IAM Roles** instead of access keys for EC2
2. **Enable VPC Flow Logs** for network monitoring
3. **Use AWS KMS** for encryption
4. **Implement WAF** for ALB protection
5. **Use Secrets Manager** for database credentials
6. **Enable CloudTrail** for auditing
7. **Use PrivateLink** for database access

### **Security Hardening**
```hcl
# Restrict SSH access
ingress {
  description = "SSH from specific IP"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["192.168.1.0/24"]  # Your office IP
}
```

## **📈 Monitoring & Maintenance**

### **CloudWatch Metrics to Monitor**
- EC2: CPUUtilization, NetworkIn, NetworkOut
- RDS: CPUUtilization, DatabaseConnections, FreeStorageSpace
- ALB: RequestCount, TargetResponseTime, UnHealthyHostCount

### **Maintenance Tasks**
```bash
# Weekly: Check for AMI updates
# Monthly: Review security groups
# Quarterly: Rotate SSH keys and database passwords
# Bi-annually: Review and update Terraform modules
```

## **🚀 Advanced Features**

### **Future Enhancements**
1. **Auto Scaling Groups**: Replace static EC2 instances
2. **CloudFront CDN**: Add global caching
3. **WAF Integration**: Add web application firewall
4. **CloudWatch Alarms**: Automated alerting
5. **CI/CD Pipeline**: Automated testing and deployment
6. **Terraform Workspaces**: Multiple environments
7. **Remote State**: Store state in S3 with locking

### **Module Refactoring**
```hcl
module "network" {
  source = "./modules/network"
  vpc_cidr = "172.16.0.0/16"
}

module "compute" {
  source = "./modules/compute"
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
}
```

## **📚 Learning Resources**

### **Terraform Documentation**
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language](https://www.terraform.io/language)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### **AWS Documentation**
- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [AWS RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/)

### **Troubleshooting Resources**
- [AWS Status Dashboard](https://status.aws.amazon.com/)
- [Terraform GitHub Issues](https://github.com/hashicorp/terraform/issues)
- [Stack Overflow Terraform Tag](https://stackoverflow.com/questions/tagged/terraform)

## **📝 Project Submission Checklist**

- [ ] All infrastructure components deployed
- [ ] Websites accessible via ALB DNS
- [ ] EC2 instances running and healthy
- [ ] RDS databases available
- [ ] Security groups properly configured
- [ ] All resources tagged appropriately
- [ ] Terraform state file secure
- [ ] README documentation complete
- [ ] Cleanup tested (terraform destroy)

## **🎓 Skills Demonstrated**
- Infrastructure as Code (IaC) with Terraform
- AWS networking (VPC, Subnets, Route Tables)
- Security group configuration
- Load balancing with ALB
- Database deployment with RDS
- SSH key management
- Tagging and resource organization
- Troubleshooting AWS services

---

**Maintained by**: Sally Munga
**Last Updated**: December 2025 
**Terraform Version**: 1.14.3  
**AWS Region**: eu-north-1 (Stockholm)  
**License**: MIT

---

*Note: This is a learning project. For production use, consult AWS Well-Architected Framework and implement additional security measures.*