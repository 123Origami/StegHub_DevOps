# Ansible Configuration Management Project

## Project Overview

This project implements an Ansible-based configuration management system for deploying and managing multi-environment infrastructure. The setup includes dynamic assignments, community roles, and conditional load balancer deployment for web applications.

## Project Structure

```
ansible-config-mgt/
├── dynamic-assignments/          # Dynamic variable assignments
│   └── env-vars.yml             # Environment variables collation
├── env-vars/                    # Environment-specific variables
│   ├── dev.yml                  # Development environment
│   ├── uat.yml                  # User Acceptance Testing environment
│   └── prod.yml                 # Production environment
├── inventory/                   # Ansible inventory files
│   ├── dev                      # Development servers
│   ├── uat                      # UAT servers  
│   └── prod                     # Production servers
├── playbooks/                   # Main playbooks
│   └── site.yml                 # Primary playbook
├── roles/                       # Ansible roles
│   ├── mysql/                   # MySQL database role (geerlingguy)
│   ├── apache/                  # Apache web server role (geerlingguy)
│   ├── nginx/                   # Nginx load balancer role
│   ├── php/                     # PHP role (geerlingguy)
│   └── webserver/               # Custom web server role
└── static-assignments/          # Static playbook assignments
    ├── common.yml               # Common configuration
    ├── webservers.yml           # Web server setup
    ├── uat-webservers.yml       # UAT-specific web setup
    ├── database.yml             # Database server setup
    └── loadbalancers.yml        # Load balancer configuration
```

## Features

### 1. Dynamic Assignments
- Environment-specific variable loading
- Automatic variable collation based on inventory
- Fallback to default values when environment files don't exist

### 2. Community Roles Integration
- **MySQL**: `geerlingguy.mysql` - Database setup and configuration
- **Apache**: `geerlingguy.apache` - Web server installation
- **PHP**: `geerlingguy.php` - PHP runtime environment
- **PHP-MySQL**: `geerlingguy.php-mysql` - PHP MySQL extensions

### 3. Multi-Environment Support
- **Development (dev)**: Basic setup without load balancers
- **UAT**: Full setup with Nginx load balancer
- **Production (prod)**: Production-ready with load balancers

### 4. Conditional Load Balancer Deployment
- Switch between Nginx and Apache load balancers
- Environment-specific load balancer configuration
- Conditional role execution based on variables

## Prerequisites

- Ansible 2.9+
- Python 3.6+
- SSH access to target servers
- Ubuntu or Amazon Linux servers

## Configuration

### Environment Variables

Each environment has its own variable file in `env-vars/`:

**uat.yml example:**
```yaml
env_name: user-acceptance-testing
enable_nginx_lb: true
enable_apache_lb: false
load_balancer_is_required: true

mysql_root_password: "SecureRootPassword123!"
mysql_databases:
  - name: tooling
    encoding: utf8
    collation: utf8_general_ci
mysql_users:
  - name: tooling_user
    host: "%"
    password: "ToolingUserPass123!"
    priv: "tooling.*:ALL,GRANT"

nginx_upstream_servers:
  - "web1-uat:80"
  - "web2-uat:80"
```

### Inventory Setup

Create inventory files for each environment with server IPs:

**inventory/uat:**
```ini
[uat_webservers]
web1-uat ansible_host=<Private IP Here>
web2-uat ansible_host=<Private IP Here>

[webservers:children]
uat_webservers

[db]
db-uat ansible_host=<Private IP Here>

[lb]
lb-uat ansible_host=<Private IP Here>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/<Key pair value>
```

## Usage

### 1. Syntax Check
```bash
ansible-playbook --syntax-check -i inventory/uat playbooks/site.yml
```

### 2. Dry Run
```bash
ansible-playbook --check -i inventory/uat playbooks/site.yml
```

### 3. Deploy to UAT
```bash
ansible-playbook -i inventory/uat playbooks/site.yml
```

### 4. Deploy to Production
```bash
ansible-playbook -i inventory/prod playbooks/site.yml
```

### 5. Run Specific Components
```bash
# Only webservers
ansible-playbook -i inventory/uat playbooks/site.yml --tags webservers

# Only load balancers
ansible-playbook -i inventory/uat playbooks/site.yml --tags loadbalancers

# Only database
ansible-playbook -i inventory/uat playbooks/site.yml --tags database
```

## Load Balancer Configuration

### Switching Load Balancers

**To use Nginx:**
```yaml
# In env-vars/uat.yml
enable_nginx_lb: true
enable_apache_lb: false
load_balancer_is_required: true
```

**To use Apache:**
```yaml
# In env-vars/dev.yml
enable_nginx_lb: false
enable_apache_lb: true
load_balancer_is_required: true
```

**To disable load balancer:**
```yaml
load_balancer_is_required: false
```

## Key Playbooks

### site.yml
Main playbook that orchestrates the entire deployment:
- Loads environment variables
- Applies common configuration
- Deploys web servers
- Configures database
- Sets up load balancers (conditionally)

### Static Assignments
- **common.yml**: Base system configuration
- **webservers.yml**: Apache, PHP, and application setup
- **database.yml**: MySQL database configuration
- **loadbalancers.yml**: Load balancer setup (Nginx/Apache)

## Customization

### Adding New Environments
1. Create new inventory file in `inventory/`
2. Create environment variables in `env-vars/`
3. Update server IPs and specific configurations

### Adding New Roles
1. Install community roles: `ansible-galaxy install role.name -p roles/`
2. Create custom roles in `roles/` directory
3. Update relevant playbooks to include new roles

### Modifying Database Configuration
Edit `roles/mysql/defaults/main.yml`:
```yaml
mysql_databases:
  - name: your_database
    encoding: utf8
    collation: utf8_general_ci

mysql_users:
  - name: your_user
    host: "%"
    password: "your_password"
    priv: "your_database.*:ALL,GRANT"
```

## Security Notes

- Change default passwords in environment variable files
- Use Ansible Vault for sensitive data in production
- Restrict database user privileges based on application needs
- Configure firewall rules appropriately

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key path in inventory and ansible.cfg
   - Check username (ubuntu vs ec2-user)
   - Ensure security groups allow SSH access

2. **Role Not Found**
   - Verify roles are installed in `roles/` directory
   - Check `ansible.cfg` for correct `roles_path`
   - Use full paths in role references if needed

3. **YAML Syntax Errors**
   - Validate YAML syntax: `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"`
   - Check indentation and formatting

### Debug Commands

```bash
# Verbose output
ansible-playbook -i inventory/uat playbooks/site.yml -v

# List all tasks
ansible-playbook -i inventory/uat playbooks/site.yml --list-tasks

# Test connectivity
ansible -i inventory/uat all -m ping
```

## Contributing

1. Create feature branch: `git checkout -b feature-name`
2. Make changes and test
3. Commit changes: `git commit -m "Description"`
4. Push to branch: `git push origin feature-name`
5. Create Pull Request

## License

This project is for educational purposes as part of DevOps training.

## Related Projects

- [Ansible Galaxy](https://galaxy.ansible.com/) - Community roles repository
- [Ansible Documentation](https://docs.ansible.com/) - Official documentation

---
