# AWS Cloud Solution for 2 Company Websites Using Reverse Proxy Technology

## 📋 **Project Overview**
This project builds a secure, scalable AWS infrastructure hosting two websites (WordPress and Tooling) using NGINX as a reverse proxy. The architecture includes auto-scaling groups, multi-AZ deployment, RDS MySQL database, EFS shared storage, and Application Load Balancers. This setup is designed for the **EU (Ireland) - eu-west-1** region.

## ⚠️ **CRITICAL WARNINGS**
- **NOT covered by AWS Free Tier** - Costs can accumulate rapidly
- **Estimated cost**: €0.65-€0.95/hour if running in eu-west-1
- **Maximum safe runtime**: 6-8 hours
- **MANDATORY**: Delete all resources immediately after completion
- **REQUIRED**: Set up AWS Budget Alerts before starting

## 🚀 **Prerequisites Setup (1-2 Hours)**

### **Step 1: AWS Account Organization**
1. **Create Master/Root AWS Account**
   - Visit https://aws.amazon.com/free/
   - Sign up with primary email
   - Complete verification process

2. **Create Sub-account (DevOps)**
   - Login to AWS Organizations console
   - Click "Add an AWS account"
   - Account name: `DevOps`
   - Email: Use a different email address (can use email alias)
   - IAM role name: `OrganizationAccountAccessRole`

3. **Create Organizational Unit (OU)**
   - In AWS Organizations, click "Create new OU"
   - Name: `Dev`
   - Description: "Development environment OU"

4. **Move Account to OU**
   - Select the DevOps account
   - Actions → Move → Select "Dev" OU

5. **Switch to DevOps Account**
   - Use "Switch Role" feature in AWS console
   - Account ID: DevOps account ID
   - Role: `OrganizationAccountAccessRole`
   - Display name: `DevOps-Role`
   - **IMPORTANT**: Select Region: **EU (Ireland) - eu-west-1**

### **Step 2: Domain Registration**
1. **Register Free Domain**
   - Visit https://www.freenom.com (as it is currently down I would reccomend duckdns.org as a           replacement) Offers up to 5 free domains
   - Search for available domain (e.g., yourcompany.tk, .ml, .ga, .cf, .gq)
   - Complete registration (requires email verification)

2. **AWS Route53 Setup**
   ```bash
   # In AWS Console:
   # 1. Go to Route53 → Hosted zones → Create hosted zone
   # 2. Domain name: yourdomain.tk
   # 3. Type: Public hosted zone
   # 4. Region: eu-west-1
   # 5. Click Create
   ```

3. **Update Nameservers at Freenom**
   - Copy all 4 Route53 nameservers (e.g., ns-xxx.awsdns-xx.com)
   - Login to Freenom → My Domains → Manage Domain → Management Tools → Nameservers
   - Select "Use custom nameservers"
   - Paste all 4 Route53 nameservers
   - Save changes (propagation takes 5-60 minutes)

## 🌐 **Phase 1: VPC & Network Infrastructure (2-3 Hours)**

### **Step 3: Create Virtual Private Cloud (VPC)**
1. **Navigate to VPC Console**
   - Services → VPC → Your VPCs → Create VPC
   - **Ensure Region selector shows: EU (Ireland) - eu-west-1**

2. **Configure VPC Settings**
   ```
   Resources to create: VPC only
   Name tag: Project-VPC
   IPv4 CIDR: 10.0.0.0/16
   IPv6 CIDR block: No IPv6 CIDR block
   Tenancy: Default
   Tags: 
     Key=Project, Value=ReverseProxyProject
     Key=Environment, Value=dev
     Key=Automated, Value=No
   ```

3. **Enable DNS Settings**
   - Select your VPC → Actions → Edit DNS settings
   - ✅ Enable DNS hostnames: Yes
   - ✅ Enable DNS resolution: Yes
   - Save changes

### **Step 4: Create Subnets (6 Total) in eu-west-1**
**eu-west-1 Availability Zones:**
- **eu-west-1a** (Dublin)
- **eu-west-1b** (Dublin)
- **eu-west-1c** (Dublin)

**Public Subnets (Internet Accessible):**
1. **Public-1**
   ```
   Name: Public-1-eu-west-1a
   VPC: Project-VPC
   Availability Zone: eu-west-1a
   IPv4 CIDR: 10.0.1.0/24
   Auto-assign public IP: ✅ Enable
   ```

2. **Public-2**
   ```
   Name: Public-2-eu-west-1b
   VPC: Project-VPC
   Availability Zone: eu-west-1b
   IPv4 CIDR: 10.0.2.0/24
   Auto-assign public IP: ✅ Enable
   ```

**Private Subnets (Web Servers):**
3. **Private-1**
   ```
   Name: Private-1-eu-west-1a
   VPC: Project-VPC
   Availability Zone: eu-west-1a
   IPv4 CIDR: 10.0.3.0/24
   Auto-assign public IP: ❌ Disable
   ```

4. **Private-2**
   ```
   Name: Private-2-eu-west-1b
   VPC: Project-VPC
   Availability Zone: eu-west-1b
   IPv4 CIDR: 10.0.4.0/24
   Auto-assign public IP: ❌ Disable
   ```

**Data Layer Subnets (RDS/EFS):**
5. **Data-1**
   ```
   Name: Data-1-eu-west-1a
   VPC: Project-VPC
   Availability Zone: eu-west-1a
   IPv4 CIDR: 10.0.5.0/24
   Auto-assign public IP: ❌ Disable
   ```

6. **Data-2**
   ```
   Name: Data-2-eu-west-1b
   VPC: Project-VPC
   Availability Zone: eu-west-1b
   IPv4 CIDR: 10.0.6.0/24
   Auto-assign public IP: ❌ Disable
   ```

### **Step 5: Internet Gateway & Route Tables**
1. **Create Internet Gateway**
   ```
   Name: Project-IGW
   Attach to: Project-VPC
   ```

2. **Create Public Route Table**
   ```
   Name: Public-RT
   VPC: Project-VPC
   
   Routes:
   Destination: 0.0.0.0/0
   Target: igw-xxx (Internet Gateway)
   
   Subnet Associations:
   ✅ Public-1-eu-west-1a
   ✅ Public-2-eu-west-1b
   ```

3. **Create Private Route Table**
   ```
   Name: Private-RT
   VPC: Project-VPC
   
   Subnet Associations:
   ✅ Private-1-eu-west-1a
   ✅ Private-2-eu-west-1b
   ✅ Data-1-eu-west-1a
   ✅ Data-2-eu-west-1b
   ```

### **Step 6: NAT Gateway Setup**
1. **Allocate 3 Elastic IPs in eu-west-1**
   ```
   # In VPC Console → Elastic IPs → Allocate Elastic IP address
   # Important: Network border group MUST be "eu-west-1"
   # Repeat 3 times:
   - Name: EIP-1, EIP-2, EIP-3
   - Network border group: eu-west-1
   - Tags: Project=ReverseProxyProject
   ```

2. **Create NAT Gateway**
   ```
   Name: Project-NAT
   Subnet: Public-1-eu-west-1a
   Elastic IP allocation: EIP-1
   Connectivity type: Public
   ```

3. **Update Private Route Table**
   ```
   Add route:
   Destination: 0.0.0.0/0
   Target: nat-xxx (NAT Gateway)
   ```

### **Step 7: Security Groups Configuration**
**Create in this order:**

1. **ALB-SG** (Load Balancer Security Group)
   ```
   Inbound Rules:
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0 (for redirection)
   
   Outbound Rules:
   - All traffic
   
   Tags:
   Name: ALB-SecurityGroup
   Project: ReverseProxyProject
   Environment: dev
   ```

2. **Nginx-SG** (Nginx Security Group)
   ```
   Inbound Rules:
   - Type: HTTPS, Port: 443, Source: ALB-SG
   - Type: SSH, Port: 22, Source: Bastion-SG
   - Type: HTTP, Port: 80, Source: ALB-SG (for health checks)
   
   Outbound Rules:
   - All traffic
   
   Tags:
   Name: Nginx-SecurityGroup
   Project: ReverseProxyProject
   ```

3. **Bastion-SG** (Bastion Host Security Group)
   ```
   # Get your public IP:
   curl ifconfig.me
   # Or: dig +short myip.opendns.com @resolver1.opendns.com
   
   Inbound Rules:
   - Type: SSH, Port: 22, Source: YOUR_PUBLIC_IP/32
   
   Outbound Rules:
   - All traffic
   
   Tags:
   Name: Bastion-SecurityGroup
   ```

4. **Webserver-SG** (Web Server Security Group)
   ```
   Inbound Rules:
   - Type: HTTP, Port: 80, Source: Nginx-SG
   - Type: HTTPS, Port: 443, Source: Nginx-SG
   - Type: SSH, Port: 22, Source: Bastion-SG
   
   Outbound Rules:
   - All traffic
   
   Tags:
   Name: Webserver-SecurityGroup
   ```

5. **Data-SG** (Database & Storage Security Group)
   ```
   Inbound Rules:
   - Type: MYSQL/Aurora, Port: 3306, Source: Webserver-SG
   - Type: NFS, Port: 2049, Source: Nginx-SG
   - Type: NFS, Port: 2049, Source: Webserver-SG
   
   Outbound Rules:
   - All traffic
   
   Tags:
   Name: Data-SecurityGroup
   ```

## 💻 **Phase 2: Compute Resources - NGINX (2-3 Hours)**

### **Step 8: Create NGINX AMI in eu-west-1**
1. **Find CentOS AMI for eu-west-1**
   ```
   Search AMI: "CentOS 7 x86_64"
   Owner: aws-marketplace
   AMI ID for eu-west-1: ami-0ff760b16d28e05f4
   Alternative: ami-0a8e758f5e873d1c1 (CentOS 7.9)
   
   OR use Amazon Linux 2 (cheaper, better support):
   Amazon Linux 2 AMI: ami-0c1c30571d2dae5c9
   ```

2. **Launch EC2 Instance in eu-west-1**
   ```
   AMI: Amazon Linux 2 (recommended) or CentOS 7
   Instance type: t2.micro
   Network: Project-VPC
   Subnet: Public-1-eu-west-1a
   Auto-assign public IP: Enable
   Security group: Nginx-SG
   Key pair: Create new (nginx-key-eu, download .pem file)
   
   Storage: 8 GB gp2
   Tags: 
     Name: Nginx-Base-Instance
     Project: ReverseProxyProject
     Component: NGINX
   ```

3. **Connect via SSH and Configure**
   ```bash
   # Connect to instance
   ssh -i nginx-key-eu.pem ec2-user@<PUBLIC_IP>
   # Note: Amazon Linux uses 'ec2-user', CentOS uses 'centos'
   
   # Update system (Amazon Linux)
   sudo yum update -y
   
   # Install required packages
   sudo yum install -y python3 ntp net-tools vim wget telnet htop
   
   # Install NGINX (Amazon Linux extras)
   sudo amazon-linux-extras install nginx1 -y
   # For CentOS: sudo yum install -y nginx
   
   # Create health check page
   sudo mkdir -p /usr/share/nginx/html
   echo "Nginx Health Check" | sudo tee /usr/share/nginx/html/healthstatus
   
   # Configure NGINX (basic config)
   sudo cat > /etc/nginx/nginx.conf << 'EOF'
   user nginx;
   worker_processes auto;
   error_log /var/log/nginx/error.log;
   pid /run/nginx.pid;
   
   events {
       worker_connections 1024;
   }
   
   http {
       log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for"';
   
       access_log /var/log/nginx/access.log main;
   
       sendfile on;
       tcp_nopush on;
       tcp_nodelay on;
       keepalive_timeout 65;
       types_hash_max_size 2048;
   
       include /etc/nginx/mime.types;
       default_type application/octet-stream;
   
       server {
           listen 80;
           server_name _;
           root /usr/share/nginx/html;
           
           location /healthstatus {
               access_log off;
               return 200 "healthy\n";
               add_header Content-Type text/plain;
           }
           
           location / {
               return 503 "Service Not Configured\n";
               add_header Content-Type text/plain;
           }
       }
   }
   EOF
   
   # Start and enable NGINX
   sudo systemctl start nginx
   sudo systemctl enable nginx
   
   # Verify installation
   curl http://localhost/healthstatus
   
   # Configure timezone for eu-west-1
   sudo timedatectl set-timezone Europe/Dublin
   ```

4. **Create AMI from Instance**
   ```
   # In EC2 Console (eu-west-1 region):
   # 1. Select instance → Actions → Image and templates → Create image
   # 2. Image name: nginx-base-ami-eu
   # 3. Image description: "NGINX reverse proxy base image for eu-west-1"
   # 4. No reboot: Unchecked
   # 5. Tags: Project=ReverseProxyProject, Component=NGINX, Region=eu-west-1
   # 6. Click Create Image
   
   # Wait 5-10 minutes for AMI creation
   # Note AMI ID: ami-xxxxxxxx
   ```

### **Step 9: Create Launch Template for NGINX**
1. **Create Launch Template in eu-west-1**
   ```
   Name: nginx-launch-template-eu
   Template version description: Initial version for eu-west-1
   AMI: nginx-base-ami-eu (search by name)
   Instance type: t2.micro
   Key pair: nginx-key-eu
   
   Network settings:
   - Subnet: Don't include in launch template
   - Security groups: Select Nginx-SG
   
   Storage: 8 GB gp2
   
   Advanced details:
   - IAM instance profile: None (or create one for SSM access)
   - Shutdown behavior: Terminate
   - Termination protection: Disable
   
   - User data (paste as text):
     #!/bin/bash
     #!/bin/bash
     # Update system
     yum update -y
     
     # Install EFS utilities (will be used later)
     yum install -y amazon-efs-utils
     
     # Ensure NGINX is running
     systemctl start nginx
     systemctl enable nginx
     
     # Create health check endpoint
     mkdir -p /usr/share/nginx/html
     echo "healthy" > /usr/share/nginx/html/healthstatus
     
     # Log initialization
     echo "NGINX instance initialized in eu-west-1 at $(date)" >> /var/log/user-data.log
     echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /var/log/user-data.log
     
     # Set timezone
     timedatectl set-timezone Europe/Dublin
   ```

### **Step 10: Create Target Group for NGINX**
1. **Configure Target Group in eu-west-1**
   ```
   Name: nginx-target-group-eu
   Target type: Instances
   Protocol: HTTPS
   Port: 443
   VPC: Project-VPC
   
   Health checks:
   - Protocol: HTTP
   - Path: /healthstatus
   - Port: 80
   - Healthy threshold: 2
   - Unhealthy threshold: 2
   - Timeout: 5 seconds
   - Interval: 30 seconds
   - Success codes: 200
   
   Tags:
   - Project: ReverseProxyProject
   - Component: NGINX
   ```

### **Step 11: Create Auto Scaling Group for NGINX**
1. **Configure Auto Scaling Group in eu-west-1**
   ```
   Name: nginx-asg-eu
   Launch template: nginx-launch-template-eu
   Version: Latest ($Latest)
   
   Network:
   - VPC: Project-VPC
   - Subnets: Public-1-eu-west-1a, Public-2-eu-west-1b
   
   Load balancing:
   - Attach to an existing load balancer
   - Choose from your load balancer target groups: nginx-target-group-eu
   - Health check type: ELB
   - Health check grace period: 300 seconds
   
   Group size:
   - Desired capacity: 2
   - Minimum capacity: 2
   - Maximum capacity: 4
   
   Scaling policies:
   - Add scaling policy
   - Policy type: Target tracking
   - Metric type: Average CPU utilization
   - Target value: 90%
   - Instances need: 300 seconds
   
   Notifications:
   - Create SNS topic: nginx-scaling-notifications-eu
   - Email: your-email@example.com
   - Notification types: Launch, Terminate, Fail to launch, Fail to terminate
   
   Tags:
   - Key: Project, Value: ReverseProxyProject
   - Key: Environment, Value: dev
   - Key: Automated, Value: No
   - Key: Component, Value: NGINX
   ```

## 🔐 **Phase 3: Compute Resources - Bastion Hosts (1-2 Hours)**

### **Step 12: Create Bastion AMI in eu-west-1**
1. **Launch EC2 Instance**
   ```
   AMI: Amazon Linux 2 (ami-0c1c30571d2dae5c9)
   Instance type: t2.micro
   Subnet: Public-1-eu-west-1a
   Security group: Bastion-SG
   Key pair: bastion-key-eu (create new)
   ```

2. **Configure Bastion**
   ```bash
   ssh -i bastion-key-eu.pem ec2-user@<PUBLIC_IP>
   
   # Update and install
   sudo yum update -y
   sudo yum install -y python3 ntp net-tools vim wget telnet htop
   
   # Install Ansible and Git
   sudo amazon-linux-extras install ansible2 -y
   sudo yum install -y git
   
   # Configure SSH for internal access
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   
   # Create SSH config for internal hosts
   cat > ~/.ssh/config << 'EOF'
   Host 10.0.*
       User ec2-user
       IdentityFile ~/.ssh/internal-key-eu
       StrictHostKeyChecking no
       UserKnownHostsFile /dev/null
       ConnectTimeout 10
   
   Host webserver-*
       User ec2-user
       IdentityFile ~/.ssh/internal-key-eu
       StrictHostKeyChecking no
       UserKnownHostsFile /dev/null
   
   Host nginx-*
       User ec2-user
       IdentityFile ~/.ssh/internal-key-eu
       StrictHostKeyChecking no
       UserKnownHostsFile /dev/null
   EOF
   chmod 600 ~/.ssh/config
   
   # Install monitoring tools
   sudo yum install -y iftop nmon nc
   
   # Set timezone
   sudo timedatectl set-timezone Europe/Dublin
   ```

3. **Create AMI**
   ```
   Name: bastion-base-ami-eu
   Description: "Bastion host with Ansible and Git for eu-west-1"
   Tags: Project=ReverseProxyProject, Component=Bastion, Region=eu-west-1
   ```

### **Step 13: Configure Bastion Infrastructure**
1. **Create Launch Template**
   ```
   Name: bastion-launch-template-eu
   AMI: bastion-base-ami-eu
   Instance type: t2.micro
   Key pair: bastion-key-eu
   Security group: Bastion-SG
   
   User data:
   #!/bin/bash
   # Update system
   yum update -y
   
   # Install additional monitoring tools
   yum install -y glances sysstat
   
   # Configure CloudWatch agent (optional)
   yum install -y amazon-cloudwatch-agent
   
   # Log initialization
   echo "Bastion initialized in eu-west-1 at $(date)" >> /var/log/bastion-init.log
   echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> /var/log/bastion-init.log
   
   # Set timezone
   timedatectl set-timezone Europe/Dublin
   ```

2. **Create Target Group**
   ```
   Name: bastion-target-group-eu
   Target type: Instances
   Protocol: TCP
   Port: 22
   VPC: Project-VPC
   Health checks: TCP:22
   ```

3. **Create Auto Scaling Group**
   ```
   Name: bastion-asg-eu
   Launch template: bastion-launch-template-eu
   Subnets: Public-1-eu-west-1a, Public-2-eu-west-1b
   Desired: 2, Min: 2, Max: 2 (Bastions don't need to scale much)
   Health check: EC2
   No load balancer needed for bastions
   ```

4. **Associate Elastic IPs**
   ```
   # After instances are launched:
   # 1. Go to EC2 → Instances (eu-west-1)
   # 2. Select bastion instance
   # 3. Actions → Networking → Associate Elastic IP
   # 4. Select EIP-2 for first bastion
   # 5. Repeat for second bastion with EIP-3
   
   # Alternative: Use Elastic IPs in launch template via network interfaces
   ```

## 🌍 **Phase 4: Compute Resources - Web Servers (2-3 Hours)**

### **Step 14: Create WordPress AMI in eu-west-1**
1. **Launch EC2 Instance**
   ```
   AMI: Amazon Linux 2 (ami-0c1c30571d2dae5c9)
   Instance type: t2.micro
   Subnet: Private-1-eu-west-1a
   Security group: Webserver-SG
   Key pair: internal-key-eu (create new)
   No public IP (private subnet)
   ```

2. **Configure WordPress via Bastion**
   ```bash
   # First SSH to bastion using its Elastic IP
   ssh -i bastion-key-eu.pem ec2-user@<BASTION_EIP>
   
   # From bastion, SSH to private instance using its private IP
   # You'll need to copy internal-key-eu.pem to bastion first
   scp -i bastion-key-eu.pem internal-key-eu.pem ec2-user@<BASTION_EIP>:~/.ssh/
   
   # Now SSH from bastion to private instance
   ssh -i ~/.ssh/internal-key-eu.pem ec2-user@<PRIVATE_IP>
   
   # Install Apache and PHP (Amazon Linux 2)
   sudo yum update -y
   sudo amazon-linux-extras install php7.4 -y
   sudo yum install -y httpd php php-mysqlnd php-fpm php-json php-gd php-mbstring php-xml
   
   # Install additional tools
   sudo yum install -y python3 ntp net-tools vim wget telnet htop
   
   # Download and install WordPress
   cd /tmp
   wget https://wordpress.org/latest.tar.gz
   tar -xzf latest.tar.gz
   
   # Configure WordPress
   sudo mv wordpress /var/www/html/
   sudo chown -R apache:apache /var/www/html/wordpress
   
   # Create wp-config.php template
   sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
   
   # Set permissions
   sudo chmod 755 /var/www/html/wordpress
   sudo chmod 644 /var/www/html/wordpress/wp-config.php
   
   # Configure Apache
   sudo cat > /etc/httpd/conf.d/wordpress.conf << 'EOF'
   <VirtualHost *:80>
       ServerAdmin webmaster@yourdomain.tk
       DocumentRoot /var/www/html/wordpress
       ServerName yourdomain.tk
       
       <Directory /var/www/html/wordpress>
           Options FollowSymLinks
           AllowOverride All
           Require all granted
       </Directory>
       
       ErrorLog /var/log/httpd/wordpress_error.log
       CustomLog /var/log/httpd/wordpress_access.log combined
   </VirtualHost>
   EOF
   
   # Enable and start Apache
   sudo systemctl enable httpd
   sudo systemctl start httpd
   
   # Configure timezone
   sudo timedatectl set-timezone Europe/Dublin
   ```

3. **Create AMI**
   ```
   Name: wordpress-base-ami-eu
   Description: "WordPress with Apache and PHP for eu-west-1"
   Tags: Project=ReverseProxyProject, Component=WordPress, Region=eu-west-1
   ```

### **Step 15: Create Tooling AMI in eu-west-1**
1. **Launch Similar Instance**
   ```
   Same AMI and configuration as WordPress
   Subnet: Private-1-eu-west-1a
   Security group: Webserver-SG
   ```

2. **Configure Tooling Website**
   ```bash
   # From bastion, connect to tooling instance
   ssh -i ~/.ssh/internal-key-eu.pem ec2-user@<TOOLING_PRIVATE_IP>
   
   # Install Apache and PHP
   sudo yum update -y
   sudo amazon-linux-extras install php7.4 -y
   sudo yum install -y httpd php php-mysqlnd php-fpm php-json git
   
   # Clone tooling repository (replace with your repo)
   cd /var/www/html
   sudo git clone https://github.com/yourusername/tooling.git
   # OR create a simple PHP info page for testing
   sudo rm -rf tooling
   sudo mkdir tooling
   sudo cat > /var/www/html/tooling/index.php << 'EOF'
   <?php
   phpinfo();
   ?>
   EOF
   
   # Set permissions
   sudo chown -R apache:apache /var/www/html/tooling
   
   # Create Apache config
   sudo cat > /etc/httpd/conf.d/tooling.conf << 'EOF'
   <VirtualHost *:80>
       ServerAdmin devops@yourdomain.tk
       DocumentRoot /var/www/html/tooling
       ServerName tooling.yourdomain.tk
       
       <Directory /var/www/html/tooling>
           Options FollowSymLinks
           AllowOverride All
           Require all granted
       </Directory>
       
       ErrorLog /var/log/httpd/tooling_error.log
       CustomLog /var/log/httpd/tooling_access.log combined
   </VirtualHost>
   EOF
   
   # Restart Apache
   sudo systemctl restart httpd
   ```

3. **Create AMI**
   ```
   Name: tooling-base-ami-eu
   Description: "Tooling website for eu-west-1"
   Tags: Project=ReverseProxyProject, Component=Tooling, Region=eu-west-1
   ```

### **Step 16: Configure Web Server Auto Scaling**
**Repeat for both WordPress and Tooling:**

1. **Create Launch Templates in eu-west-1**
   ```
   WordPress: wordpress-launch-template-eu
   Tooling: tooling-launch-template-eu
   
   User data (WordPress example):
   #!/bin/bash
   # Update system
   yum update -y
   
   # Install Apache and PHP
   amazon-linux-extras install php7.4 -y
   yum install -y httpd php php-mysqlnd
   
   # Install EFS utilities
   yum install -y amazon-efs-utils
   
   # Start services
   systemctl start httpd
   systemctl enable httpd
   
   # Log initialization
   echo "WordPress instance initialized in eu-west-1 at $(date)" >> /var/log/user-data.log
   
   # Set timezone
   timedatectl set-timezone Europe/Dublin
   ```

2. **Create Target Groups in eu-west-1**
   ```
   WordPress: wordpress-target-group-eu
   Tooling: tooling-target-group-eu
   
   Configuration:
   - Protocol: HTTP
   - Port: 80
   - Health check path: / (for WordPress) or /index.php (for Tooling)
   - VPC: Project-VPC
   - Healthy threshold: 2
   - Unhealthy threshold: 2
   ```

3. **Create Auto Scaling Groups in eu-west-1**
   ```
   WordPress: wordpress-asg-eu
   Tooling: tooling-asg-eu
   
   Configuration:
   - Launch template: respective template
   - Subnets: Private-1-eu-west-1a, Private-2-eu-west-1b
   - Desired: 2, Min: 2, Max: 4
   - Health check type: ELB
   - Health check grace period: 300
   - Scaling: Target tracking, CPU > 80%
   - No load balancer yet (will attach to internal ALB)
   ```

## 🔒 **Phase 5: TLS & Load Balancers (1-2 Hours)**

### **Step 17: Request SSL Certificate in eu-west-1**
1. **Navigate to ACM (eu-west-1 region)**
   ```
   Important: ACM certificates are region-specific!
   Must be in same region as ALB (eu-west-1)
   
   Services → Certificate Manager → Request certificate
   
   Certificate type: Public
   Domain name:
   - *.yourdomain.tk (wildcard)
   - yourdomain.tk (additional name)
   
   Validation method: DNS validation
   Tags: 
     Key=Project, Value=ReverseProxyProject
     Key=Region, Value=eu-west-1
   
   Click Request
   ```

2. **Validate Certificate in Route53**
   ```
   # ACM will provide CNAME records
   # Go to Route53 (eu-west-1) → Hosted zone → Create records
   # Create the CNAME records exactly as provided by ACM
   # Example:
   Name: _xxxxxxxxxxxxx.yourdomain.tk
   Type: CNAME
   Value: _yyyyyyyyyyyyyyyyyyy.acm-validations.aws.
   TTL: 300
   
   # Wait 5-30 minutes for validation
   # Status will change from "Pending validation" to "Issued"
   ```

### **Step 18: Create External ALB (Internet-facing) in eu-west-1**
1. **Configure Load Balancer**
   ```
   Name: external-alb-eu
   Scheme: Internet-facing
   IP address type: IPv4
   Region: eu-west-1
   
   Network mapping:
   - VPC: Project-VPC
   - Subnets: Public-1-eu-west-1a, Public-2-eu-west-1b
   - ✅ Enable IPv4 address allocation
   
   Security groups: ALB-SG
   
   Listeners and routing:
   - Add listener: HTTPS:443
   - Default action: Forward to nginx-target-group-eu
   - SSL certificate: From ACM (select your issued certificate)
   - Security policy: ELBSecurityPolicy-TLS13-1-2-2021-06 (recommended)
   
   - Add another listener: HTTP:80
   - Default action: Redirect to HTTPS:443
   - Status code: HTTP 301
   
   Tags:
   - Project: ReverseProxyProject
   - Environment: dev
   - Region: eu-west-1
   ```

### **Step 19: Create Internal ALBs in eu-west-1**
**Create two internal ALBs:**

1. **WordPress Internal ALB**
   ```
   Name: wordpress-internal-alb-eu
   Scheme: Internal
   IP address type: IPv4
   Region: eu-west-1
   
   Network mapping:
   - VPC: Project-VPC
   - Subnets: Private-1-eu-west-1a, Private-2-eu-west-1b
   
   Security groups: ALB-SG
   
   Listeners:
   - HTTPS:443 → Forward to wordpress-target-group-eu
   - SSL certificate: Same ACM certificate
   
   Tags:
   - Project: ReverseProxyProject
   - Component: WordPress
   - Type: Internal-ALB
   ```

2. **Tooling Internal ALB**
   ```
   Name: tooling-internal-alb-eu
   Scheme: Internal
   IP address type: IPv4
   Region: eu-west-1
   
   Network mapping:
   - VPC: Project-VPC
   - Subnets: Private-1-eu-west-1a, Private-2-eu-west-1b
   
   Security groups: ALB-SG
   
   Listeners:
   - HTTPS:443 → Forward to tooling-target-group-eu
   - SSL certificate: Same ACM certificate
   
   Tags:
   - Project: ReverseProxyProject
   - Component: Tooling
   - Type: Internal-ALB
   ```

3. **Update Web Server Auto Scaling Groups**
   ```
   For both WordPress and Tooling ASGs:
   - Edit Auto Scaling Group
   - Load balancing: Attach to existing load balancer
   - Choose respective internal ALB target group
   - Health check type: ELB
   ```

## 💾 **Phase 6: Storage & Database (2-3 Hours)**

### **Step 20: Create EFS File System in eu-west-1**
1. **Create EFS**
   ```
   Name: project-efs-eu
   Region: eu-west-1
   VPC: Project-VPC
   
   Storage class: Standard
   Throughput mode: Bursting
   Performance mode: General Purpose
   
   Encryption: Enable
   KMS key: aws/elasticfilesystem (default)
   
   Lifecycle management:
   - Enable lifecycle management
   - Transition into IA: 30 days after last access
   - Transition out of IA: None
   
   Tags:
   - Name: project-efs-eu
   - Project: ReverseProxyProject
   - Environment: dev
   ```

2. **Create Mount Targets in eu-west-1**
   ```
   # Must create in each AZ where instances will access EFS
   # Create mount target in Data-1-eu-west-1a:
   - File system ID: fs-xxx
   - Subnet: Data-1-eu-west-1a
   - Security groups: Data-SG
   - Leave IP address auto-assigned
   
   # Create mount target in Data-2-eu-west-1b:
   - Subnet: Data-2-eu-west-1b
   - Security groups: Data-SG
   
   # Wait 2-5 minutes for mount targets to become available
   # Status should change from "Creating" to "Available"
   ```

3. **Create Access Points**
   ```
   # For WordPress:
   Name: wordpress-access-point-eu
   Path: /wordpress
   POSIX user:
     - UID: 48 (apache user ID)
     - GID: 48 (apache group ID)
   Root directory path: /wordpress
   Root directory permissions: 0755
   
   # For Tooling:
   Name: tooling-access-point-eu
   Path: /tooling
   POSIX user:
     - UID: 48
     - GID: 48
   Root directory path: /tooling
   Root directory permissions: 0755
   ```

### **Step 21: Mount EFS on Instances**
**Update Launch Template User Data:**
```bash
#!/bin/bash
# EFS Mount Script for eu-west-1
EFS_ID=fs-xxxxxxxx
WP_AP_ID=fsap-xxxxxxxx  # WordPress access point
TOOLING_AP_ID=fsap-xxxxxx  # Tooling access point

# Install EFS utilities
yum install -y amazon-efs-utils

# For WordPress instances:
if [[ $(hostname) == *"wordpress"* ]]; then
    # Create mount directory
    mkdir -p /mnt/efs/wordpress
    
    # Mount EFS via access point
    mount -t efs -o tls,accesspoint=$WP_AP_ID $EFS_ID:/ /mnt/efs/wordpress
    
    # Add to fstab for persistence
    echo "$EFS_ID:/ /mnt/efs/wordpress efs _netdev,tls,accesspoint=$WP_AP_ID 0 0" >> /etc/fstab
    
    # Create symlink for WordPress uploads
    mkdir -p /mnt/efs/wordpress/uploads
    ln -sf /mnt/efs/wordpress/uploads /var/www/html/wordpress/wp-content/uploads
fi

# For Tooling instances:
if [[ $(hostname) == *"tooling"* ]]; then
    # Create mount directory
    mkdir -p /mnt/efs/tooling
    
    # Mount EFS via access point
    mount -t efs -o tls,accesspoint=$TOOLING_AP_ID $EFS_ID:/ /mnt/efs/tooling
    
    # Add to fstab for persistence
    echo "$EFS_ID:/ /mnt/efs/tooling efs _netdev,tls,accesspoint=$TOOLING_AP_ID 0 0" >> /etc/fstab
fi
```

### **Step 22: Create KMS Key for RDS in eu-west-1**
1. **Create KMS Key**
   ```
   Services → KMS → Customer managed keys → Create key
   Region: eu-west-1
   
   Key type: Symmetric
   Key usage: Encrypt and decrypt
   
   Alias: rds-encryption-key-eu
   Description: "Key for RDS database encryption in eu-west-1"
   
   Key administrators: Add your IAM user
   Key users: 
     - Your IAM user
     - aws/rds (for RDS service to use the key)
   
   Tags: 
     Key=Project, Value=ReverseProxyProject
     Key=Region, Value=eu-west-1
     Key=Service, Value=RDS
   
   Note: KMS key cost: €1.10/month
   ```

### **Step 23: Create RDS MySQL Database in eu-west-1**
1. **Create Subnet Group in eu-west-1**
   ```
   Name: rds-subnet-group-eu
   Description: "Subnets for RDS instances in eu-west-1"
   VPC: Project-VPC
   Subnets: Data-1-eu-west-1a, Data-2-eu-west-1b
   ```

2. **Create RDS Instance in eu-west-1**
   ```
   Engine type: MySQL
   Version: MySQL 8.0.33 (latest compatible with WordPress)
   Region: eu-west-1
   
   Templates: Dev/Test (to save cost)
   
   Settings:
   - DB instance identifier: wordpress-db-eu
   - Master username: admin
   - Master password: [Generate strong password: WpDbP@ss123!]
   - Confirm password: [Same]
   
   DB instance class: db.t3.micro (cheapest in eu-west-1)
   Storage type: General Purpose SSD (gp2)
   Allocated storage: 20 GB
   ✅ Enable storage autoscaling
   Maximum storage threshold: 100 GB
   
   Connectivity:
   - VPC: Project-VPC
   - Subnet group: rds-subnet-group-eu
   - Public access: No
   - VPC security group: Data-SG
   - Availability Zone: No preference
   
   Database authentication: Password authentication
   
   Additional configuration:
   - Initial database name: wordpressdb
   - DB parameter group: default.mysql8.0
   - Option group: default:mysql-8-0
   
   Backup:
   - Backup retention period: 1 day (minimum to save cost)
   - Backup window: No preference
   - Enable automated backups: Yes
   
   Encryption: Enable encryption
   - KMS key: rds-encryption-key-eu
   
   Monitoring:
   - Enable Enhanced monitoring: Yes
   - Granularity: 60 seconds
   - Monitoring role: Default (will create if needed)
   
   Log exports: Select:
     - ✅ Error log
     - ✅ General log
     - ✅ Slow query log
   
   Maintenance:
   - Enable auto minor version upgrade: Yes
   - Maintenance window: No preference
   
   Deletion protection: Disable (for easy cleanup)
   
   Tags:
   - Key=Project, Value=ReverseProxyProject
   - Key=Environment, Value=dev
   - Key=Region, Value=eu-west-1
   - Key=Application, Value=WordPress
   
   Click Create database
   # Creation takes 5-10 minutes
   ```

3. **Note Database Endpoint**
   ```
   After creation, note:
   - Endpoint: wordpress-db-eu.xxxxxxxxxxxx.eu-west-1.rds.amazonaws.com
   - Port: 3306
   - Availability Zone: eu-west-1a (example)
   ```

## 🗺️ **Phase 7: DNS Configuration (30 Minutes)**

### **Step 24: Configure Route53 Records in eu-west-1**
1. **Create A Record for Main Domain**
   ```
   Route53 → Hosted zones → yourdomain.tk → Create record
   
   Record name: @ (leave blank for root domain)
   Record type: A - Routes traffic to an IPv4 address
   Alias: Yes
   Route traffic to: Alias to Application Load Balancer
   Region: eu-west-1
   Choose load balancer: external-alb-eu
   Evaluate target health: Yes
   
   Routing policy: Simple routing
   ```

2. **Create A Record for Tooling Subdomain**
   ```
   Record name: tooling
   Record type: A
   Alias: Yes
   Route traffic to: Alias to Application Load Balancer
   Region: eu-west-1
   Choose load balancer: external-alb-eu
   Evaluate target health: Yes
   ```

3. **Create www CNAME (Optional)**
   ```
   Record name: www
   Record type: CNAME
   Value: yourdomain.tk
   TTL: 300 seconds
   ```

4. **Verify DNS Propagation**
   ```bash
   # Check DNS resolution
   dig yourdomain.tk
   dig tooling.yourdomain.tk
   
   # Should return ALB DNS name
   # Example: external-alb-eu-123456789.eu-west-1.elb.amazonaws.com
   ```

## 🔧 **Phase 8: NGINX Reverse Proxy Configuration (1-2 Hours)**

### **Step 25: Configure NGINX Reverse Proxy via Bastion**
1. **SSH into Bastion, then NGINX Instance**
   ```bash
   # Connect to bastion
   ssh -i bastion-key-eu.pem ec2-user@<BASTION_EIP>
   
   # Get private IPs of NGINX instances
   # From EC2 console (eu-west-1), find NGINX instances private IPs
   # Or use AWS CLI:
   aws ec2 describe-instances \
     --region eu-west-1 \
     --filters "Name=tag:aws:autoscaling:groupName,Values=nginx-asg-eu" \
     --query "Reservations[].Instances[].PrivateIpAddress" \
     --output text
   
   # SSH to NGINX instance
   ssh -i ~/.ssh/internal-key-eu.pem ec2-user@<NGINX_PRIVATE_IP>
   ```

2. **Get Internal ALB DNS Names**
   ```bash
   # From AWS Console (eu-west-1), get:
   # 1. WordPress internal ALB DNS name
   # 2. Tooling internal ALB DNS name
   
   # Or use AWS CLI:
   aws elbv2 describe-load-balancers \
     --region eu-west-1 \
     --names wordpress-internal-alb-eu \
     --query "LoadBalancers[].DNSName" \
     --output text
   
   aws elbv2 describe-load-balancers \
     --region eu-west-1 \
     --names tooling-internal-alb-eu \
     --query "LoadBalancers[].DNSName" \
     --output text
   ```

3. **Update NGINX Configuration**
   ```bash
   # Backup original config
   sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
   
   # Create reverse proxy configuration
   sudo cat > /etc/nginx/conf.d/reverse-proxy.conf << 'EOF'
   # WordPress upstream configuration
   upstream wordpress_backend {
       least_conn;
       server wordpress-internal-alb-eu-xxxxxxxxxxxx.eu-west-1.elb.amazonaws.com:443;
       keepalive 32;
   }
   
   # Tooling upstream configuration
   upstream tooling_backend {
       least_conn;
       server tooling-internal-alb-eu-xxxxxxxxxxxx.eu-west-1.elb.amazonaws.com:443;
       keepalive 32;
   }
   
   # HTTPS server for main domain
   server {
       listen 443 ssl http2;
       server_name yourdomain.tk www.yourdomain.tk;
       
       # SSL configuration - Using ALB SSL termination, so no certs needed on NGINX
       # SSL is terminated at ALB, traffic to NGINX is HTTP
       
       # Security headers
       add_header X-Frame-Options "SAMEORIGIN" always;
       add_header X-XSS-Protection "1; mode=block" always;
       add_header X-Content-Type-Options "nosniff" always;
       
       # Reverse proxy configuration for WordPress
       location / {
           proxy_pass https://wordpress_backend;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_set_header X-Forwarded-Host $host;
           
           proxy_connect_timeout 60s;
           proxy_send_timeout 60s;
           proxy_read_timeout 60s;
           
           proxy_buffer_size 128k;
           proxy_buffers 4 256k;
           proxy_busy_buffers_size 256k;
       }
       
       # Health check endpoint
       location /healthstatus {
           access_log off;
           return 200 "healthy\n";
           add_header Content-Type text/plain;
       }
   }
   
   # HTTPS server for tooling subdomain
   server {
       listen 443 ssl http2;
       server_name tooling.yourdomain.tk;
       
       # Security headers
       add_header X-Frame-Options "SAMEORIGIN" always;
       add_header X-XSS-Protection "1; mode=block" always;
       add_header X-Content-Type-Options "nosniff" always;
       
       # Reverse proxy configuration for Tooling
       location / {
           proxy_pass https://tooling_backend;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_set_header X-Forwarded-Host $host;
       }
       
       # Health check endpoint
       location /healthstatus {
           access_log off;
           return 200 "healthy\n";
           add_header Content-Type text/plain;
       }
   }
   
   # HTTP server - redirect all HTTP to HTTPS
   server {
       listen 80;
       server_name yourdomain.tk www.yourdomain.tk tooling.yourdomain.tk;
       
       # Redirect to HTTPS
       return 301 https://$host$request_uri;
   }
   EOF
   ```

4. **Test and Reload NGINX**
   ```bash
   # Test configuration
   sudo nginx -t
   # Should output: "nginx: configuration file /etc/nginx/nginx.conf test is successful"
   
   # Reload NGINX
   sudo systemctl reload nginx
   
   # Check NGINX status
   sudo systemctl status nginx
   ```

5. **Configure WordPress Database Connection**
   ```bash
   # SSH to WordPress instance via bastion
   # Update wp-config.php with RDS endpoint
   sudo vi /var/www/html/wordpress/wp-config.php
   
   # Update these lines:
   define( 'DB_NAME', 'wordpressdb' );
   define( 'DB_USER', 'admin' );
   define( 'DB_PASSWORD', 'WpDbP@ss123!' );
   define( 'DB_HOST', 'wordpress-db-eu.xxxxxxxxxxxx.eu-west-1.rds.amazonaws.com' );
   define( 'DB_CHARSET', 'utf8' );
   define( 'DB_COLLATE', '' );
   
   # Add for security:
   define( 'FORCE_SSL_ADMIN', true );
   
   # Restart Apache
   sudo systemctl restart httpd
   ```

## 🧪 **Phase 9: Testing & Validation (1 Hour)**

### **Step 26: Comprehensive Testing**
1. **DNS Resolution Test**
   ```bash
   # From local machine
   nslookup yourdomain.tk
   nslookup tooling.yourdomain.tk
   # Should resolve to ALB IP addresses
   ```

2. **Website Access Test**
   ```bash
   # Test via curl
   curl -I https://yourdomain.tk
   # Should return HTTP 200 or 301
   
   curl -I https://tooling.yourdomain.tk
   
   # Test with verbose SSL
   curl -v https://yourdomain.tk 2>&1 | grep -i "SSL\|certificate\|HTTP"
   ```

3. **Load Balancer Health Check**
   ```
   # In AWS Console (eu-west-1):
   # 1. EC2 → Target Groups
   # 2. Check all target groups:
   #    - nginx-target-group-eu (2 healthy)
   #    - wordpress-target-group-eu (2 healthy)
   #    - tooling-target-group-eu (2 healthy)
   ```

4. **Database Connection Test**
   ```bash
   # SSH to WordPress instance via bastion
   # Test MySQL connection
   mysql -h wordpress-db-eu.xxxxxxxxxxxx.eu-west-1.rds.amazonaws.com \
         -u admin \
         -p'WpDbP@ss123!' \
         -e "SHOW DATABASES;"
   
   # Should show wordpressdb and others
   ```

5. **EFS Mount Test**
   ```bash
   # On any instance with EFS mounted
   df -h | grep efs
   # Should show EFS mounted
   
   # Test write permissions
   sudo -u apache touch /mnt/efs/wordpress/test.txt
   ls -la /mnt/efs/wordpress/
   ```

6. **Security Group Verification**
   ```
   # Test from bastion to private instances
   ssh -i ~/.ssh/internal-key-eu.pem ec2-user@<PRIVATE_IP>
   
   # Test HTTP access between NGINX and web servers
   # From NGINX instance:
   curl http://<wordpress-private-ip>/
   curl http://<tooling-private-ip>/
   ```

7. **Auto Scaling Test (Optional)**
   ```
   # Force CPU spike to test auto-scaling
   # On NGINX instance:
   yes > /dev/null &
   # Check CloudWatch metrics and Auto Scaling events
   # Kill process after test: killall yes
   ```

## 🗑️ **Phase 10: Cleanup Procedure (30 Minutes)**

### **Step 27: Delete ALL Resources in eu-west-1 (IMPORTANT!)**
**Delete in this order to avoid dependency issues:**

1. **Delete Auto Scaling Groups**
   ```bash
   # Set desired capacity to 0 first
   # 1. nginx-asg-eu
   # 2. bastion-asg-eu
   # 3. wordpress-asg-eu
   # 4. tooling-asg-eu
   
   # Wait for instances to terminate (5-10 minutes)
   ```

2. **Delete Load Balancers**
   ```
   # 1. external-alb-eu
   # 2. wordpress-internal-alb-eu
   # 3. tooling-internal-alb-eu
   # Note: Deleting ALB automatically deletes listeners
   ```

3. **Delete Target Groups**
   ```
   # 1. nginx-target-group-eu
   # 2. wordpress-target-group-eu
   # 3. tooling-target-group-eu
   # 4. bastion-target-group-eu
   ```

4. **Delete Launch Templates**
   ```
   # 1. nginx-launch-template-eu
   # 2. bastion-launch-template-eu
   # 3. wordpress-launch-template-eu
   # 4. tooling-launch-template-eu
   ```

5. **Terminate Any Remaining EC2 Instances**
   ```
   # Check EC2 Instances console
   # Terminate any running instances
   # Wait for termination complete
   ```

6. **Delete RDS Instance**
   ```
   # 1. wordpress-db-eu
   # Options:
   # - Create final snapshot: No (unless needed)
   # - Retain automated backups: No
   # Click Delete
   # Wait 5-10 minutes
   
   # Delete RDS snapshots if any
   ```

7. **Delete EFS**
   ```
   # 1. Delete mount targets first
   # 2. Delete access points
   # 3. Delete file system: project-efs-eu
   ```

8. **Delete NAT Gateway**
   ```
   # Project-NAT
   # This will automatically disassociate the Elastic IP
   ```

9. **Release Elastic IPs**
   ```
   # Release all 3 Elastic IPs allocated in eu-west-1
   # EIP-1, EIP-2, EIP-3
   ```

10. **Delete VPC**
    ```
    # Delete Project-VPC
    # This will delete:
    # - Subnets
    # - Route tables
    # - Internet Gateway
    # - Security Groups (if no dependencies)
    # - Network ACLs
    # - VPC endpoints
    ```

11. **Delete AMIs and Snapshots**
    ```
    # Deregister AMIs:
    # 1. nginx-base-ami-eu
    # 2. bastion-base-ami-eu
    # 3. wordpress-base-ami-eu
    # 4. tooling-base-ami-eu
    
    # Delete associated snapshots
    ```

12. **Delete ACM Certificate (Optional)**
    ```
    # Delete the certificate for *.yourdomain.tk
    # Only if you don't need it anymore
    ```

13. **Delete KMS Key (Optional)**
    ```
    # rds-encryption-key-eu
    # Schedule deletion (7-30 days)
    ```

14. **Delete CloudWatch Alarms**
    ```
    # Delete auto-scaling related alarms
    # Delete custom metrics if created
    ```

15. **Delete SNS Topics**
    ```
    # nginx-scaling-notifications-eu
    # Other notification topics
    ```

### **Step 28: Verify Complete Cleanup**
```bash
# Check these services in eu-west-1:
# 1. EC2: No instances, no AMIs, no launch templates
# 2. VPC: No VPCs
# 3. RDS: No instances, no snapshots
# 4. EFS: No file systems
# 5. ELBv2: No load balancers, no target groups
# 6. Auto Scaling: No groups
# 7. CloudWatch: No alarms
# 8. S3: Delete any project buckets
# 9. IAM: Remove any created roles/policies
```

## 📝 **Cost Tracking & Budget Setup**

### **AWS Budget Setup (DO THIS FIRST!)**
1. **Create Budget Alert**
   ```
   Services → AWS Budgets → Create budget
   Budget type: Cost budget
   Period: Monthly
   Budget amount: €10.00
   
   Alert 1: Actual > €5.00
   Alert 2: Actual > €7.00  
   Alert 3: Actual > €9.00
   Alert 4: Forecasted > €8.00
   
   Email notifications: Your email
   ```

### **Estimated Costs in eu-west-1**
```
Hourly estimate:
- EC2 (8x t2.micro): €0.40/hour
- RDS (db.t3.micro): €0.045/hour
- NAT Gateway: €0.045/hour + data transfer
- ALB (3x): €0.15/hour
- EFS: €0.010/hour
- EIP (3x): €0.015/hour if not attached
- Data Transfer: Variable
Total: €0.66 - €0.95/hour

For 8-hour completion: €5.28 - €7.60
```

## 🚨 **Troubleshooting Guide**

### **Common Issues in eu-west-1**

1. **Region Mismatch**
   ```
   Problem: Resources created in wrong region
   Solution: Always verify region selector shows "EU (Ireland) eu-west-1"
   ```

2. **DNS Not Resolving**
   ```
   Problem: Domain not pointing to ALB
   Solution: Check Route53 records, verify nameserver update at Freenom
   Wait 1 hour for propagation
   ```

3. **Security Group Issues**
   ```
   Problem: Can't connect between instances
   Solution: Verify SG rules reference SG IDs, not IP addresses
   Check both inbound AND outbound rules
   ```

4. **EFS Mount Failed**
   ```
   Problem: Can't mount EFS
   Solution: Check mount targets are in correct subnets
   Verify security group allows NFS 2049
   Install amazon-efs-utils package
   ```

5. **Database Connection Refused**
   ```
   Problem: Can't connect to RDS
   Solution: Verify RDS is in same VPC, check security group
   Ensure RDS instance status is "Available"
   ```

### **Quick Fix Commands**
```bash
# Restart services
sudo systemctl restart nginx
sudo systemctl restart httpd

# Check logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/httpd/error_log

# Test connectivity
nc -zv <host> <port>
telnet <host> <port>

# Check instance metadata
curl http://169.254.169.254/latest/meta-data/
```

## ✅ **Final Checklist Before Cleanup**

- [ ] WordPress accessible: https://yourdomain.tk
- [ ] Tooling accessible: https://tooling.yourdomain.tk
- [ ] SSL certificate working (green padlock)
- [ ] All target groups healthy
- [ ] Auto scaling groups at desired capacity
- [ ] Database connected
- [ ] EFS mounted and writable
- [ ] Reverse proxy routing correctly
- [ ] All resources properly tagged
- [ ] Screenshots/documentation complete
- [ ] BUDGET ALERTS ACTIVE
- [ ] CLEANUP TIMER SET

## 📋 **Project Completion Notes**

**Time Estimate:**
- Setup: 1-2 hours
- Infrastructure: 6-8 hours  
- Testing: 1 hour
- Cleanup: 30 minutes
- **Total: 8-12 hours**

**Success Criteria:**
- Both websites accessible via HTTPS
- Auto-scaling functional
- Database connection established
- EFS shared storage working
- All security groups properly configured
- DNS correctly routing
- **ALL RESOURCES DELETED AFTER COMPLETION**

**Documentation to Keep:**
- Architecture diagram
- Resource IDs and endpoints
- Configuration files
- Cost summary
- Lessons learned
- Screenshots of working setup

---

**REMEMBER: AWS COSTS MONEY! SET A TIMER AND DELETE EVERYTHING WHEN DONE!**