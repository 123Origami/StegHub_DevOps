# Terraform Cloud Migration Project

## Complete Infrastructure Management with Terraform Cloud, Packer, and Ansible

![Terraform Cloud Architecture](https://www.terraform.io/assets/images/og-image-terraform-cloud-891adf5f.png)


##  Project Overview

This project demonstrates the migration of existing Terraform code to **Terraform Cloud** - HashiCorp's managed service for Terraform. You'll learn how to leverage Terraform Cloud for team collaboration, remote state management, and automated infrastructure deployment while integrating with Packer for custom AMI creation and Ansible for configuration management.

### What You'll Achieve
- ✅ Migrate local Terraform code to Terraform Cloud
- ✅ Set up multi-environment workflows (dev/test/prod)
- ✅ Integrate Packer for automated AMI building
- ✅ Configure infrastructure using Ansible
- ✅ Create and use private module registries
- ✅ Implement notifications and automated plans

##  Prerequisites

### Required Accounts
| Service | Purpose | Sign-up Link |
|---------|---------|--------------|
| Terraform Cloud | Main platform | [app.terraform.io/signup](https://app.terraform.io/signup) |
| GitHub | Version control | [github.com](https://github.com) |
| AWS | Cloud provider | [aws.amazon.com](https://aws.amazon.com) |

### Required Tools (Local Machine)
```bash
# Check if you have these installed
terraform --version    # >= 1.0.0
packer --version      # >= 1.8.0
ansible --version     # >= 2.9
git --version         # >= 2.30
```

### AWS Credentials
```bash
# Your AWS Access Keys should have permissions for:
# - EC2 (instances, AMIs, security groups)
# - VPC (networking components)
# - S3 (buckets)
# - IAM (roles and policies)
```



##  Project Structure

```
terraform-cloud-project/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── provider.tf
│   ├── test/
│   │   └── [similar structure]
│   └── prod/
│       └── [similar structure]
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   └── [module files]
│   └── database/
│       └── [module files]
├── packer/
│   ├── aws-ubuntu-ami.json
│   ├── scripts/
│   │   └── install-dependencies.sh
│   └── ansible/
│       └── provisioner.yml
├── ansible/
│   ├── playbooks/
│   │   ├── webserver.yml
│   │   └── database.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── nginx/
│   │   └── app/
│   ├── inventory/
│   │   ├── dev
│   │   ├── test
│   │   └── prod
│   └── ansible.cfg
├── scripts/
│   ├── setup-workspaces.sh
│   └── destroy-all.sh
├── .gitignore
├── README.md
└── terraform-cloud-guide.md
```

---

## Phase 1: Terraform Cloud Setup

### Step 1.1: Create Account and Organization

1. **Navigate to Terraform Cloud**: [https://app.terraform.io](https://app.terraform.io)

2. **Sign Up**:
   ```
   - Click "Sign up" or "Create an account"
   - Use email or GitHub account
   - Verify email address
   ```

3. **Create Organization**:
   ```
   - Select "Start from scratch"
   - Organization name: [yourname]-terraform-cloud
   - Example: john-doe-terraform-cloud
   - Click "Create organization"
   ```

### Step 1.2: Understand Pricing Tiers

| Feature | Free Tier | Paid Tier |
|---------|-----------|-----------|
| Users | Up to 5 | Unlimited |
| State storage | Included | Included |
| Runs | 3 concurrent | 10+ concurrent |
| Policy as Code | No | Yes |
| SSO | No | Yes |

---

## Phase 2: GitHub Integration

### Step 2.1: Prepare Repository

```bash
# Create and clone repository
mkdir terraform-cloud-project
cd terraform-cloud-project
git init
git remote add origin https://github.com/yourusername/terraform-cloud-project.git

# Create .gitignore
cat > .gitignore << EOF
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Packer files
packer_cache/
!packer/*.json

# Ansible files
*.retry
EOF
```

### Step 2.2: Add Your Terraform Code

Copy your existing Terraform code from previous projects:

```hcl
# main.tf - Example structure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/networking"
  
  environment    = var.environment
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = {
    Name        = "${var.environment}-web-server"
    Environment = var.environment
  }
}
```

### Step 2.3: Create Workspace

1. **In Terraform Cloud Dashboard**:
   - Click "New workspace"
   - Select "Version control workflow"
   - Choose "GitHub"
   - Authorize Terraform Cloud if prompted
   - Select your repository

2. **Workspace Configuration**:
   ```
   Workspace Name: dev-infrastructure
   Description: Development environment infrastructure
   Terraform Working Directory: environments/dev
   Branch: main (will change later)
   ```

3. **Configure Variables**:
   - Navigate to "Variables" tab
   - Add AWS credentials:
   
   **Environment Variables** (Sensitive):
   ```
   AWS_ACCESS_KEY_ID = AKIAXXXXXXXXXXXXXXXX
   AWS_SECRET_ACCESS_KEY = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```
   
   **Terraform Variables**:
   ```
   aws_region = us-east-1
   environment = dev
   instance_type = t2.micro
   ```

### Step 2.4: First Manual Run

```bash
# Push code to trigger first run
git add .
git commit -m "Initial Terraform code for dev environment"
git push origin main
```

**In Terraform Cloud UI**:
1. Go to "Runs" tab
2. Click "Queue plan manually"
3. Wait for plan to complete
4. Review the plan output
5. Click "Confirm & apply"
6. Add comment: "Initial infrastructure deployment"
7. Click "Confirm plan"

---

## Phase 3: Multi-Environment Configuration

### Step 3.1: Create Environment Branches

```bash
# Create branches for different environments
git checkout -b dev
git push origin dev

git checkout -b test
git push origin test

git checkout -b prod
git push origin prod

# Return to main
git checkout main
```

### Step 3.2: Restructure for Environments

Organize your code by environment:

```hcl
# environments/dev/main.tf
terraform {
  cloud {
    organization = "your-organization-name"
    
    workspaces {
      name = "dev-infrastructure"
    }
  }
}

module "vpc" {
  source = "../../modules/networking"
  
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
}

module "compute" {
  source = "../../modules/compute"
  
  environment     = "dev"
  instance_type   = "t2.micro"
  instance_count  = 2
  subnet_ids      = module.vpc.public_subnet_ids
}
```

```hcl
# environments/test/main.tf
terraform {
  cloud {
    organization = "your-organization-name"
    
    workspaces {
      name = "test-infrastructure"
    }
  }
}

module "vpc" {
  source = "../../modules/networking"
  
  environment = "test"
  vpc_cidr    = "10.1.0.0/16"
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.10.0/24", "10.1.11.0/24"]
}

module "compute" {
  source = "../../modules/compute"
  
  environment     = "test"
  instance_type   = "t2.small"
  instance_count  = 3
  subnet_ids      = module.vpc.public_subnet_ids
}
```

```hcl
# environments/prod/main.tf
terraform {
  cloud {
    organization = "your-organization-name"
    
    workspaces {
      name = "prod-infrastructure"
    }
  }
}

module "vpc" {
  source = "../../modules/networking"
  
  environment = "prod"
  vpc_cidr    = "10.2.0.0/16"
  public_subnets  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnets = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
}

module "compute" {
  source = "../../modules/compute"
  
  environment     = "prod"
  instance_type   = "t2.medium"
  instance_count  = 5
  subnet_ids      = module.vpc.public_subnet_ids
}
```

### Step 3.3: Create Workspaces for Each Environment

**For Development:**
1. Create workspace: `dev-infrastructure`
2. Connect to GitHub
3. Branch: `dev`
4. Working directory: `environments/dev`
5. Variables: Dev-specific values

**For Test:**
1. Create workspace: `test-infrastructure`
2. Connect to GitHub
3. Branch: `test`
4. Working directory: `environments/test`
5. Variables: Test-specific values

**For Production:**
1. Create workspace: `prod-infrastructure`
2. Connect to GitHub
3. Branch: `prod`
4. Working directory: `environments/prod`
5. Variables: Production-specific values

### Step 3.4: Configure Auto-Apply for Dev Only

**In dev-infrastructure workspace:**
1. Go to **Settings** → **General**
2. Under **Apply Method**, check **"Auto apply"**
3. Click **"Save settings"**

**In test and prod workspaces:**
- Leave auto-apply disabled for manual approval

### Step 3.5: Test Environment Workflow

```bash
# Make changes in dev branch
git checkout dev
echo "# Test change in dev" >> environments/dev/main.tf
git add .
git commit -m "Test auto-apply for dev"
git push origin dev
```

**Expected Results:**
- Dev workspace automatically runs plan and apply
- Test and prod workspaces require manual approval

---

## Phase 4: Packer Integration for AMI Building

### Step 4.1: Install Packer

```bash
# macOS
brew install packer

# Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Windows (Chocolatey)
choco install packer
```

### Step 4.2: Create Packer Configuration

```json
# packer/aws-ubuntu-ami.json
{
  "variables": {
    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
    "region": "us-east-1",
    "instance_type": "t2.micro",
    "environment": "dev",
    "source_ami": "ami-0c7217cdde317cfec",
    "ssh_username": "ubuntu"
  },
  "builders": [
    {
      "type": "amazon-ebs",
      "access_key": "{{user `aws_access_key`}}",
      "secret_key": "{{user `aws_secret_key`}}",
      "region": "{{user `region`}}",
      "instance_type": "{{user `instance_type`}}",
      "source_ami": "{{user `source_ami`}}",
      "ssh_username": "{{user `ssh_username`}}",
      "ami_name": "custom-ubuntu-{{user `environment`}}-{{timestamp}}",
      "ami_description": "Custom Ubuntu AMI for {{user `environment`}} environment",
      "tags": {
        "Name": "custom-ubuntu-{{user `environment`}}",
        "Environment": "{{user `environment`}}",
        "ManagedBy": "Packer",
        "BuildTime": "{{timestamp}}"
      },
      "run_tags": {
        "Name": "packer-builder-{{user `environment`}}",
        "Environment": "{{user `environment`}}"
      }
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline": [
        "sudo apt-get update",
        "sudo apt-get upgrade -y",
        "sudo apt-get install -y python3 python3-pip python3-apt",
        "sudo apt-get install -y nginx",
        "sudo systemctl enable nginx",
        "sudo apt-get install -y git curl wget",
        "sudo apt-get install -y docker.io",
        "sudo systemctl enable docker",
        "sudo usermod -aG docker ubuntu"
      ]
    },
    {
      "type": "file",
      "source": "packer/scripts/",
      "destination": "/tmp/scripts/"
    },
    {
      "type": "shell",
      "script": "packer/scripts/install-dependencies.sh"
    },
    {
      "type": "ansible",
      "playbook_file": "packer/ansible/provisioner.yml",
      "ansible_env_vars": [
        "ANSIBLE_HOST_KEY_CHECKING=False"
      ]
    }
  ],
  "post-processors": [
    {
      "type": "manifest",
      "output": "packer/manifest.json",
      "strip_path": true
    }
  ]
}
```

### Step 4.3: Create Provisioning Scripts

```bash
# packer/scripts/install-dependencies.sh
#!/bin/bash

set -e

echo "Starting dependency installation..."

# Install Node.js (if needed)
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python dependencies
pip3 install --upgrade pip
pip3 install boto3 awscli ansible

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configure nginx
sudo tee /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo systemctl restart nginx

echo "Dependencies installed successfully!"
```

### Step 4.4: Create Ansible Provisioner for Packer

```yaml
# packer/ansible/provisioner.yml
---
- name: Configure instance during AMI build
  hosts: all
  become: yes
  gather_facts: yes
  
  vars:
    app_user: ubuntu
    app_directory: /opt/application
    
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
        
    - name: Install common packages
      apt:
        name:
          - htop
          - vim
          - tree
          - net-tools
          - jq
          - unzip
        state: present
        
    - name: Create application directory
      file:
        path: "{{ app_directory }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'
        
    - name: Create welcome page
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Welcome</title>
          </head>
          <body>
              <h1>Server provisioned with Packer + Ansible</h1>
              <p>Hostname: {{ ansible_hostname }}</p>
              <p>IP Address: {{ ansible_default_ipv4.address }}</p>
              <p>Environment: {{ lookup('env', 'ENVIRONMENT') | default('dev', true) }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
        
    - name: Set up log rotation
      template:
        src: logrotate.conf.j2
        dest: /etc/logrotate.d/application
        mode: '0644'
```

### Step 4.5: Build AMI with Packer

```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export ENVIRONMENT="dev"

# Validate Packer template
packer validate packer/aws-ubuntu-ami.json

# Build the AMI
packer build \
  -var "environment=dev" \
  -var "region=us-east-1" \
  packer/aws-ubuntu-ami.json

# Build for different environments
packer build -var "environment=test" packer/aws-ubuntu-ami.json
packer build -var "environment=prod" packer/aws-ubuntu-ami.json
```

### Step 4.6: Integrate AMI with Terraform

```hcl
# modules/compute/main.tf
data "aws_ami" "custom" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["custom-ubuntu-${var.environment}-*"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.custom.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = <<-EOF
    #!/bin/bash
    echo "Environment: ${var.environment}" > /etc/environment
    echo "Instance started at $(date)" >> /var/log/startup.log
  EOF
  
  tags = {
    Name        = "${var.environment}-web-server"
    Environment = var.environment
    AMI         = data.aws_ami.custom.id
    ManagedBy   = "Terraform"
  }
}
```

---

## Phase 5: Ansible Integration for Configuration Management

### Step 5.1: Install Ansible

```bash
# macOS
brew install ansible

# Ubuntu/Debian
sudo apt update
sudo apt install ansible -y

# Using pip
pip3 install ansible

# Verify installation
ansible --version
```

### Step 5.2: Create Ansible Directory Structure

```bash
mkdir -p ansible/{playbooks,roles,inventory,group_vars,host_vars}

# Create ansible.cfg
cat > ansible/ansible.cfg << EOF
[defaults]
inventory = inventory/
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_cache
stdout_callback = yaml
callback_whitelist = profile_tasks

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-%%h-%%p-%%r
EOF
```

### Step 5.3: Create Inventory Files

```ini
# ansible/inventory/dev
[webservers]
dev-web-01 ansible_host=10.0.1.10 ansible_user=ubuntu
dev-web-02 ansible_host=10.0.1.11 ansible_user=ubuntu

[databases]
dev-db-01 ansible_host=10.0.10.10 ansible_user=ubuntu

[loadbalancers]
dev-lb-01 ansible_host=10.0.1.20 ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
environment=dev
```

```ini
# ansible/inventory/prod
[webservers]
prod-web-01 ansible_host=10.2.1.10 ansible_user=ubuntu
prod-web-02 ansible_host=10.2.1.11 ansible_user=ubuntu
prod-web-03 ansible_host=10.2.1.12 ansible_user=ubuntu

[databases]
prod-db-01 ansible_host=10.2.10.10 ansible_user=ubuntu
prod-db-02 ansible_host=10.2.10.11 ansible_user=ubuntu

[loadbalancers]
prod-lb-01 ansible_host=10.2.1.20 ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
environment=prod
```

### Step 5.4: Create Ansible Playbooks

```yaml
# ansible/playbooks/webserver.yml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  gather_facts: yes
  
  vars_files:
    - "../group_vars/{{ environment }}/webservers.yml"
  
  roles:
    - role: common
      tags: [common]
    
    - role: nginx
      tags: [nginx]
    
    - role: app
      tags: [app]
    
    - role: monitoring
      tags: [monitoring]
      when: environment == "prod"
  
  post_tasks:
    - name: Verify nginx is running
      uri:
        url: http://localhost
        method: GET
        status_code: 200
      register: nginx_check
      
    - name: Log configuration completion
      debug:
        msg: "Web server configuration completed for {{ inventory_hostname }}"
```

```yaml
# ansible/playbooks/database.yml
---
- name: Configure database servers
  hosts: databases
  become: yes
  gather_facts: yes
  
  vars:
    db_port: 3306
    db_bind_address: "0.0.0.0"
    
  pre_tasks:
    - name: Set database name based on environment
      set_fact:
        db_name: "{{ 'production_db' if environment == 'prod' else 'development_db' }}"
        
  roles:
    - role: common
    - role: mysql
      vars:
        mysql_root_password: "{{ vault_mysql_root_password }}"
        mysql_databases:
          - name: "{{ db_name }}"
            encoding: utf8mb4
        mysql_users:
          - name: "{{ db_user }}"
            host: "%"
            password: "{{ vault_db_password }}"
            priv: "{{ db_name }}.*:ALL"
            
  post_tasks:
    - name: Create database backup script
      template:
        src: backup.sh.j2
        dest: /usr/local/bin/backup-db.sh
        mode: '0755'
        
    - name: Add cron job for backups
      cron:
        name: "database backup"
        hour: 2
        minute: 0
        job: "/usr/local/bin/backup-db.sh"
```

### Step 5.5: Create Ansible Roles

```yaml
# ansible/roles/common/tasks/main.yml
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
    
- name: Install common packages
  apt:
    name:
      - curl
      - wget
      - git
      - htop
      - tree
      - vim
      - net-tools
      - jq
      - unzip
      - python3-pip
    state: present
    
- name: Set timezone
  timezone:
    name: "{{ timezone | default('UTC') }}"
    
- name: Create common directories
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /opt/application
    - /var/log/application
    - /data/backups
```

```yaml
# ansible/roles/nginx/tasks/main.yml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    
- name: Create nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart nginx
  
- name: Create site configuration
  template:
    src: site.conf.j2
    dest: /etc/nginx/sites-available/{{ site_name | default('default') }}
  notify: reload nginx
  
- name: Enable site
  file:
    src: /etc/nginx/sites-available/{{ site_name | default('default') }}
    dest: /etc/nginx/sites-enabled/{{ site_name | default('default') }}
    state: link
  notify: reload nginx
  
- name: Remove default site
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: reload nginx
  
- name: Start and enable nginx
  service:
    name: nginx
    state: started
    enabled: yes
```

```yaml
# ansible/roles/nginx/handlers/main.yml
---
- name: restart nginx
  service:
    name: nginx
    state: restarted
    
- name: reload nginx
  service:
    name: nginx
    state: reloaded
```

```jinja2
# ansible/roles/nginx/templates/nginx.conf.j2
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
    
    # Virtual host configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### Step 5.6: Run Ansible Playbooks

```bash
# Test connection to all hosts
ansible all -i ansible/inventory/dev -m ping

# Run webserver playbook for dev
ansible-playbook -i ansible/inventory/dev ansible/playbooks/webserver.yml

# Run with specific tags
ansible-playbook -i ansible/inventory/dev ansible/playbooks/webserver.yml --tags "nginx"

# Run for production with vault
ansible-playbook -i ansible/inventory/prod \
  ansible/playbooks/webserver.yml \
  --vault-password-file ~/.vault_pass \
  --extra-vars "environment=prod"
```

### Step 5.7: Integrate Ansible with Terraform

```hcl
# modules/compute/main.tf - Add Ansible inventory generation
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    web_servers = aws_instance.web_server
    db_servers  = aws_instance.database
    environment = var.environment
  })
  filename = "../../ansible/inventory/${var.environment}"
}

resource "null_resource" "run_ansible" {
  depends_on = [aws_instance.web_server, aws_instance.database]
  
  triggers = {
    instance_ids = join(",", aws_instance.web_server[*].id)
  }
  
  provisioner "local-exec" {
    command = <<EOF
      cd ../../ansible
      ansible-playbook -i inventory/${var.environment} \
        playbooks/webserver.yml \
        --extra-vars "environment=${var.environment}"
    EOF
  }
}
```

```jinja2
# modules/compute/templates/inventory.tpl
{% for server in web_servers %}
web-{{ environment }}-{{ loop.index0 }} ansible_host={{ server.public_ip }} ansible_user=ubuntu
{% endfor %}

{% for server in db_servers %}
db-{{ environment }}-{{ loop.index0 }} ansible_host={{ server.private_ip }} ansible_user=ubuntu
{% endfor %}

[webservers]
{% for server in web_servers %}
web-{{ environment }}-{{ loop.index0 }}
{% endfor %}

[databases]
{% for server in db_servers %}
db-{{ environment }}-{{ loop.index0 }}
{% endfor %}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
environment={{ environment }}
```

---

## Phase 6: Private Module Registry

### Step 6.1: Create a Module Repository

```bash
# Create module repository
mkdir terraform-module-vpc
cd terraform-module-vpc
git init

# Create module files
```

```hcl
# main.tf - VPC Module
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-public-subnet-${count.index + 1}"
      Type = "Public"
    }
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-subnet-${count.index + 1}"
      Type = "Private"
    }
  )
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0
  vpc   = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nat-gw"
    }
  )
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-public-rt"
    }
  )
}

resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.enable_nat_gateway ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
```

```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

```hcl
# outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_id" {
  description = "ID of NAT gateway"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "internet_gateway_id" {
  description = "ID of internet gateway"
  value       = aws_internet_gateway.main.id
}
```

```hcl
# README.md for module
# Terraform AWS VPC Module

This module creates a VPC with public and private subnets, internet gateway, and NAT gateway.

## Usage

```hcl
module "vpc" {
  source = "app.terraform.io/your-organization/vpc/aws"
  version = "1.0.0"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | n/a | yes |
| vpc_cidr | CIDR block for VPC | string | n/a | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | n/a | yes |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | n/a | yes |
| availability_zones | List of AZs | list(string) | ["us-east-1a", "us-east-1b", "us-east-1c"] | no |
| enable_nat_gateway | Enable NAT gateway | bool | true | no |
| tags | Tags to apply | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| public_subnet_cidrs | Public subnet CIDRs |
| private_subnet_cidrs | Private subnet CIDRs |
```

### Step 6.2: Publish Module to Private Registry

1. **Push module to GitHub:**
```bash
git add .
git commit -m "Initial VPC module"
git remote add origin https://github.com/yourusername/terraform-module-vpc.git
git push -u origin main
```

2. **In Terraform Cloud:**
   - Go to **Registry** → **Modules**
   - Click **"Add module"**
   - Select **"GitHub"**
   - Choose your `terraform-module-vpc` repository
   - Module name: `vpc`
   - Provider: `aws`
   - Track branch: `main`
   - Click **"Publish module"**

### Step 6.3: Use the Module

```hcl
# environments/dev/main.tf
terraform {
  cloud {
    organization = "your-organization"
    
    workspaces {
      name = "dev-infrastructure"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "app.terraform.io/your-organization/vpc/aws"
  version = "1.0.0"
  
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  
  tags = {
    ManagedBy = "Terraform"
    Project   = "terraform-cloud-demo"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}
```

### Step 6.4: Version Your Module

```bash
# Create a new version
git tag -a "v1.0.1" -m "Add support for multiple AZs"
git push origin v1.0.1

# In Terraform Cloud, the new version will be automatically detected
```

---

## Phase 7: Notifications and Monitoring

### Step 7.1: Configure Email Notifications

**For each workspace:**

1. Navigate to **Settings** → **Notifications**
2. Click **"Create notification"**
3. Configure:
   ```
   Name: Email Alerts
   Destination: Email
   Email: your-email@example.com
   
   Triggers:
   ✓ All checks (or select specific)
     - Run started
     - Plan completed
     - Apply started
     - Apply completed
     - Run errored
     - Run needs attention
   ```
4. Click **"Create notification"**

### Step 7.2: Configure Slack Notifications

1. **Create Slack Incoming Webhook:**
   - Go to [api.slack.com/apps](https://api.slack.com/apps)
   - Click **"Create New App"**
   - Choose **"From scratch"**
   - Name: "Terraform Cloud Notifications"
   - Select workspace
   - Enable **"Incoming Webhooks"**
   - Click **"Add New Webhook to Workspace"**
   - Select channel
   - Copy webhook URL

2. **In Terraform Cloud workspace:**
   - Go to **Settings** → **Notifications**
   - Click **"Create notification"**
   - Configure:
     ```
     Name: Slack Alerts
     Destination: Slack
     URL: (paste webhook URL)
     
     Triggers:
     ✓ Run started
     ✓ Run completed
     ✓ Run errored
     ```
   - Click **"Create notification"**

### Step 7.3: Test Notifications

```bash
# Trigger a test by making a small change
git checkout dev
echo "# Testing notifications" >> environments/dev/main.tf
git add .
git commit -m "Test notifications"
git push origin dev
```

**Expected notifications:**
- Email: Run started notification
- Slack: Run started message
- After plan completes: Additional notifications
- After apply (if auto-applied): Completion notification

---

## Phase 8: Destroying Infrastructure

### Step 8.1: Destroy Individual Workspace

**Via Web UI:**
1. Navigate to workspace
2. Go to **Settings** → **Destruction and Deletion**
3. Click **"Queue destroy plan"**
4. Type workspace name to confirm
5. Click **"Queue destroy plan"**
6. Review destroy plan
7. Click **"Confirm & apply"**

**Via API (optional):**
```bash
# Get workspace ID
WORKSPACE_ID=$(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/your-organization/workspaces/dev-infrastructure \
  | jq -r '.data.id')

# Create destroy run
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{
    "data": {
      "attributes": {
        "is-destroy": true,
        "message": "Destroy infrastructure"
      },
      "type": "runs",
      "relationships": {
        "workspace": {
          "data": {
            "type": "workspaces",
            "id": "'$WORKSPACE_ID'"
          }
        }
      }
    }
  }' \
  https://app.terraform.io/api/v2/runs
```

### Step 8.2: Create Destroy Script

```bash
#!/bin/bash
# scripts/destroy-all.sh

set -e

echo " Starting infrastructure destruction..."

# List of workspaces to destroy
WORKSPACES=("dev-infrastructure" "test-infrastructure" "prod-infrastructure")

for WORKSPACE in "${WORKSPACES[@]}"; do
  echo " Destroying $WORKSPACE..."
  
  # Queue destroy plan
  curl \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data '{
      "data": {
        "attributes": {
          "is-destroy": true,
          "message": "Automated destruction"
        },
        "type": "runs",
        "relationships": {
          "workspace": {
            "data": {
              "type": "workspaces",
              "id": "'$(get_workspace_id $WORKSPACE)'"
            }
          }
        }
      }
    }' \
    https://app.terraform.io/api/v2/runs
    
  echo " Destroy queued for $WORKSPACE"
done

echo " All destruction jobs queued successfully!"
```

---

## Best Practices

### 1. **State Management**
```hcl
# Always use remote state with locking
terraform {
  backend "remote" {
    organization = "your-organization"
    
    workspaces {
      prefix = "infra-"
    }
  }
}
```

### 2. **Variable Organization**
```hcl
# Use terraform.tfvars for environment-specific values
# Use variables.tf for declarations with descriptions
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}
```

### 3. **Tagging Strategy**
```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform Cloud"
    Project     = "terraform-cloud-demo"
    CostCenter  = "12345"
    Owner       = "devops-team"
  }
}

resource "aws_instance" "web" {
  # ... configuration ...
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-web-server"
    Role = "webserver"
  })
}
```

### 4. **Security Best Practices**
```hcl
# Always mark sensitive variables
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Use AWS Secrets Manager or Parameter Store for secrets
data "aws_secretsmanager_secret" "db_password" {
  name = "db-password-${var.environment}"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}
```

### 5. **Cost Control**
```hcl
# Use terraform plan to estimate costs
# Set up budget alerts in AWS
# Use auto-stop for non-production environments
resource "aws_ec2_scheduled_action" "stop_instances" {
  count = var.environment != "prod" ? 1 : 0
  
  name     = "stop-instances"
  schedule = "cron(0 20 * * ? *)"  # 8 PM daily
  
  # ... configuration ...
}
```

---

## Troubleshooting Guide

### Common Issues and Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **AWS Credentials** | `No valid credential sources found` | Verify AWS keys in workspace variables, ensure they're marked as Environment Variables |
| **GitHub Connection** | `Failed to fetch repository` | Re-authenticate GitHub in Terraform Cloud settings → Providers |
| **Plan Failed** | `Error: Failed to parse...` | Check Terraform syntax, validate locally with `terraform validate` |
| **Apply Failed** | `Error creating resource` | Check AWS permissions, resource limits, or dependency issues |
| **State Lock** | `Error: Error acquiring the state lock` | Wait or force unlock from Terraform Cloud UI |
| **Module Not Found** | `Error: module not found` | Check module source path and version in private registry |

### Debugging Commands

```bash
# Enable debug logging locally
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Validate Terraform configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan with detailed output
terraform plan -detailed-exitcode

# Check Terraform Cloud run logs
# In UI, click on run → "Download logs" for detailed debugging
```

### Verification Checklist

- [ ] Terraform Cloud account created and verified
- [ ] Organization created successfully
- [ ] GitHub repository created with Terraform code
- [ ] Workspace connected to GitHub
- [ ] AWS credentials configured as environment variables
- [ ] First manual plan and apply successful
- [ ] Automatic plan triggered on git push
- [ ] Dev, test, prod branches created
- [ ] Three workspaces configured for each branch
- [ ] Auto-apply enabled only for dev workspace
- [ ] Email notifications working
- [ ] Slack notifications working (if configured)
- [ ] Packer builds AMIs successfully
- [ ] Ansible configures instances properly
- [ ] Private module published and usable
- [ ] Destroy operation works as expected

---

##  Conclusion

Congratulations! You have successfully:

✅ Migrated Terraform code to Terraform Cloud  
✅ Set up multi-environment infrastructure  
✅ Integrated Packer for custom AMI building  
✅ Configured infrastructure with Ansible  
✅ Created and used private module registry  
✅ Implemented notifications and monitoring  
✅ Learned destruction and cleanup procedures  

### Next Steps

1. **Explore Terraform Cloud Advanced Features:**
   - Sentinel policies for compliance
   - Cost estimation
   - Team management and RBAC

2. **CI/CD Integration:**
   - Integrate with GitHub Actions
   - Add automated testing
   - Implement approval workflows

3. **Multi-Cloud Expansion:**
   - Add Azure or GCP resources
   - Cross-cloud networking

4. **Monitoring and Observability:**
   - Integrate with Datadog or CloudWatch
   - Set up dashboards
   - Implement logging solutions

### Additional Resources

- [Terraform Cloud Documentation](https://www.terraform.io/docs/cloud)
- [Packer Documentation](https://www.packer.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

##  License
