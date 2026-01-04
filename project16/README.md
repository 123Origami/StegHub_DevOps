# **AWS Infrastructure Automation with Terraform - Project 201**

## **📋 Project Overview**

This project implements a **multi-tier, highly available web application infrastructure** on AWS using Terraform. The architecture follows best practices for security, scalability, and reliability, featuring a reverse proxy layer, internal/external load balancers, auto-scaling groups, shared storage, and managed databases.

---

## **🏗️ Architecture Diagram**

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                             │
└────────────────────────────┬────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  External ALB   │  ← Public facing load balancer
                    │  (Internet)     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Nginx Reverse  │  ← Security & routing layer
                    │     Proxy       │
                    │   (Auto Scaling)│
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Internal ALB   │  ← Private load balancer
                    │   (Internal)    │
                    └───────┬─────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
        ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
        │  Bastion  │ │ WordPress │ │  Tooling  │
        │   Host    │ │   ASG     │ │    ASG    │
        │ (SSH)     │ │           │ │           │
        └───────────┘ └─────┬─────┘ └─────┬─────┘
                            │             │
                    ┌───────▼─────────────▼───────┐
                    │        Shared Resources     │
                    ├─────────────────────────────┤
                    │  • EFS (Shared Storage)     │
                    │  • RDS MySQL Database       │
                    │  • Security Groups          │
                    │  • VPC Networking           │
                    └─────────────────────────────┘
```

---

## **🛠️ Prerequisites**

### **1. AWS Account Setup**
- AWS Account with IAM user credentials
- IAM User with AdministratorAccess or equivalent permissions
- AWS CLI configured (`aws configure`)

### **2. Local Development Environment**
- **Terraform** v1.0 or later
- **AWS CLI** v2.0 or later
- **Git** for version control
- **Text editor** (VS Code recommended)
- **SSH key pair** created in AWS Console

### **3. Required Knowledge**
- Basic understanding of AWS services (EC2, VPC, ALB, RDS, EFS)
- Basic Linux command line skills
- Understanding of networking concepts (CIDR, subnets, routing)
- Familiarity with Terraform syntax

---

## **📁 Project Structure**

```
terraform-pbl-201/
├── main.tf                    # Core VPC and subnet configuration
├── variables.tf              # Input variable definitions
├── terraform.tfvars          # Variable values (customize this!)
├── outputs.tf                # Output values for reference
├── internet_gateway.tf       # Internet Gateway configuration
├── natgateway.tf             # NAT Gateway for private subnets
├── route_tables.tf           # Route tables and associations
├── roles.tf                  # IAM roles and policies
├── security.tf               # Security groups with layered security
├── cert.tf                   # ACM SSL certificates (optional)
├── alb.tf                    # External and Internal ALBs
├── asg-bastion-nginx.tf      # Bastion and Nginx Auto Scaling Groups
├── asg-wordpress-tooling.tf  # WordPress and Tooling Auto Scaling Groups
├── efs.tf                    # Elastic File System configuration
├── rds.tf                    # RDS MySQL database
├── user-data/               # Bootstrap scripts for instances
│   ├── bastion.sh
│   ├── nginx.sh
│   ├── wordpress.sh
│   └── tooling.sh
└── README.md                # This file
```

---

## **🔧 Configuration Steps**

### **Step 1: Clone/Setup Project**
```bash
# Create project directory
mkdir terraform-pbl-201
cd terraform-pbl-201

# Create all Terraform files
# (Copy the code from the previous sections)
```

### **Step 2: Update Configuration Variables**
Edit `terraform.tfvars` with your values:

```hcl
# REQUIRED: Update these values for your environment
region = "us-east-1"                     # AWS region
ami = "ami-0b0af3577fe5e3532"            # Ubuntu 20.04 AMI for your region
keypair = "your-key-pair-name"           # AWS Key Pair name
account_no = "123456789012"              # Your AWS Account Number

# Database credentials (CHANGE THESE!)
db-username = "admin"
db-password = "SecurePassword123!"       # Use a strong password

# Optional: For custom domain (if using Route53)
# domain = "yourdomain.com"
```

### **Step 3: Create AWS Resources**
```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration (creates ~40 AWS resources)
terraform apply -auto-approve

# Note: Deployment takes 10-15 minutes
# RDS takes the longest to provision (5-10 minutes)
```

### **Step 4: Access Your Infrastructure**
After successful deployment:

```bash
# Get the external ALB DNS name
terraform output alb_dns_name

# Access in browser: http://<alb-dns-name>
# Or for tooling: http://tooling.<your-domain> (if configured)

# Get bastion host SSH access info
terraform output bastion_asg_name
# Check AWS Console for bastion instance public IP
```

### **Step 5: Testing**
1. **External ALB**: Access via browser - should show Nginx default page
2. **Bastion Host**: SSH to bastion (if security groups allow your IP)
3. **Internal Services**: WordPress/Tooling apps behind internal ALB
4. **Database**: Verify RDS endpoint from outputs

### **Step 6: Cleanup**
```bash
# Destroy all resources (IMPORTANT to avoid charges)
terraform destroy -auto-approve

# Verify destruction
terraform show
```

---

## **🏗️ Resource Breakdown**

### **Networking Layer**
- **VPC**: 172.16.0.0/16 CIDR
- **Public Subnets**: 2 subnets across 2 AZs
- **Private Subnets**: 4 subnets across 2 AZs
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: For private subnet outbound internet
- **Route Tables**: Separate public/private routing

### **Compute Layer**
- **Bastion Host**: Secure SSH jump host in public subnet
- **Nginx ASG**: Reverse proxy (2 instances max)
- **WordPress ASG**: Application servers (2 instances max)
- **Tooling ASG**: Tooling application (2 instances max)

### **Load Balancing**
- **External ALB**: Internet-facing (port 443)
- **Internal ALB**: Private network only
- **Target Groups**: Health-checked endpoints
- **Listeners**: HTTPS routing rules

### **Storage & Database**
- **EFS**: Shared file system with KMS encryption
- **Access Points**: /wordpress and /tooling mount points
- **RDS MySQL**: Multi-AZ database with encryption

### **Security**
- **Layered Security Groups**: Micro-segmentation
- **IAM Roles**: Least privilege access
- **KMS**: Encryption for EFS and RDS
- **Network ACLs**: Default AWS NACLs

---

## **🔒 Security Features**

1. **Network Segmentation**
   - Public/private subnet separation
   - No direct internet access to application servers
   - Bastion host as single entry point

2. **Security Groups**
   - Principle of least privilege
   - Reference security groups instead of CIDR blocks
   - Specific port allowances only

3. **Encryption**
   - EFS encrypted at rest with KMS
   - RDS encrypted at rest
   - HTTPS for ALB listeners

4. **Access Control**
   - IAM roles for EC2 instances
   - No hardcoded credentials
   - Instance profiles for temporary credentials

---

## **💰 Cost Estimation**

**Important**: Destroy resources immediately after testing!

| Resource | Type | Estimated Cost/Hour | Notes |
|----------|------|---------------------|-------|
| EC2 Instances | t2.micro (x6 max) | ~$0.012 each | Free Tier eligible |
| RDS MySQL | db.t2.micro | ~$0.017 | Free Tier eligible |
| ALB | Application Load Balancer | ~$0.0225 | + LCU charges |
| NAT Gateway | Standard | ~$0.045 | + data processing |
| EFS | General Purpose | ~$0.30/GB-month | Minimal for testing |
| **TOTAL** | **Per Hour** | **~$0.15 - $0.25** | **Destroy after use!** |

**Estimated Monthly Cost if left running: $100-150**

---

## **🚨 Common Issues & Troubleshooting**

### **Issue: Terraform Plan/Apply Errors**
```bash
# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Check AWS credentials
aws sts get-caller-identity
```

### **Issue: Timeout during RDS creation**
- RDS takes 5-10 minutes to provision
- Be patient or check AWS Console for status
- Use `terraform refresh` if stuck

### **Issue: Security Group conflicts**
```bash
# Check existing security groups
aws ec2 describe-security-groups --query 'SecurityGroups[].GroupName'

# Use unique names or destroy previous deployment first
terraform destroy
terraform apply
```

### **Issue: AMI not found**
```bash
# Get Ubuntu AMI for your region
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
  --query 'Images[*].[ImageId,CreationDate,Name]' \
  --output text | sort -k2 -r | head -1
```

---

## **📝 Assignment Submission Requirements**

### **1. Code Submission**
- Complete Terraform code in the specified structure
- All 14+ Terraform files properly configured
- User data scripts for bootstrap
- Working `terraform.tfvars` with your configuration

### **2. Documentation**
- Architecture diagram (can be hand-drawn)
- Explanation of networking concepts used
- Summary of security implementation
- Cost analysis and optimization suggestions

### **3. Verification Steps**
1. Successful `terraform apply` output
2. Screenshots of AWS Console showing:
   - VPC with subnets
   - Running EC2 instances
   - ALB endpoints
   - RDS database
   - EFS file system
3. `terraform output` showing all resources

### **4. Additional Tasks (From Project)**
1. **Networking Concepts Summary**: Explain IP addressing, subnets, CIDR, routing, IGW, NAT
2. **OSI/TCP-IP Model**: Compare and explain the 7-layer OSI vs 4-layer TCP/IP model
3. **IAM Concepts**: Difference between `assume role policy` and `role policy`

---

## **🎯 Learning Objectives**

### **Technical Skills**
- Infrastructure as Code with Terraform
- AWS multi-tier architecture design
- Auto Scaling Groups and Load Balancing
- Network security and segmentation
- Database and storage configuration

### **Architectural Concepts**
- High availability across Availability Zones
- Security by design (layered security)
- Scalability patterns (horizontal scaling)
- Cost optimization strategies
- Disaster recovery considerations

### **Operational Excellence**
- Tagging strategies for resource management
- Monitoring and notification setup
- Backup and recovery procedures
- Change management processes

---

## **📚 Additional Resources**

### **Documentation**
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### **Learning Materials**
- [Eli the Computer Guy - Networking](https://youtu.be/rL8RSFQG8do)
- [Digital Ocean - Networking Tutorials](https://www.digitalocean.com/community/tags/networking)
- [AWS Training - Architecting on AWS](https://aws.amazon.com/training/course-descriptions/architecting/)

### **Tools & Extensions**
- **VS Code Extensions**: HashiCorp Terraform, AWS Toolkit
- **Terraform Tools**: tfsec, tflint, terraform-docs
- **Diagram Tools**: draw.io, Lucidchart, Excalidraw

---

## **⚠️ Important Warnings**

1. **COST ALERT**: This creates billable AWS resources. Destroy immediately after testing.
2. **SECURITY**: Change all default passwords before production use.
3. **REGION**: Use the same region consistently to avoid cross-region charges.
4. **LIMITS**: Check AWS service limits in your account before deployment.
5. **BACKUP**: This is a learning exercise - not production-ready without modifications.

---

## **✅ Success Checklist**

- [ ] All Terraform files created with correct code
- [ ] `terraform.tfvars` customized with your values
- [ ] `terraform init` successful
- [ ] `terraform plan` shows no errors
- [ ] `terraform apply` completes successfully
- [ ] Resources visible in AWS Console
- [ ] ALB accessible via browser
- [ ] `terraform destroy` removes all resources
- [ ] Additional tasks documented
- [ ] Screenshots captured for submission

---

## **📞 Support & Help**

### **When Stuck:**
1. Check Terraform error messages
2. Verify AWS Console for resource status
3. Review AWS service limits
4. Check CloudTrail logs for API errors
5. Use `terraform state list` to verify created resources

### **Common Pitfalls to Avoid:**
- Using wrong AMI for your region
- Insufficient IAM permissions
- VPC/Subnet CIDR conflicts
- Security group rule conflicts
- RDS parameter mismatches

---

**Remember**: Infrastructure as Code is both powerful and dangerous. Always test in a sandbox environment, use version control, and follow the principle of least privilege. Happy automating! 🚀

**Deployment Time**: 10-15 minutes  
**Cleanup Command**: `terraform destroy -auto-approve`  
**Estimated Cost/Hour**: $0.15 - $0.25  
**Critical Action**: DESTROY AFTER TESTING!