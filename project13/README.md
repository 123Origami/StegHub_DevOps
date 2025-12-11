End-to-End CI/CD Pipeline for PHP Applications with Jenkins, Ansible, Artifactory & SonarQube
📋 Project Overview
This project implements a complete CI/CD pipeline for PHP-based applications (Tooling and TODO web apps) using modern DevOps tools. The pipeline automates building, testing, security scanning, quality gating, and deployment across multiple environments. For testing purposes, I configured all tools to run on localhost to minimize costs and simplify the setup process.

🎯 Objectives
Implement continuous integration and delivery for PHP applications

Configure Jenkins for pipeline orchestration (running locally)

Integrate SonarQube for code quality analysis (running locally)

Use Artifactory as a binary repository manager (running locally)

Deploy applications across multiple environments using Ansible

Implement quality gates to ensure only quality code reaches production

🏗️ Architecture
Local Testing Setup
For testing and development purposes, I configured the entire CI/CD pipeline to run on localhost:

Jenkins Server: Running on localhost:8080

SonarQube Server: Running on localhost:9000

Artifactory Server: Running on localhost:8081

Ansible Control Node: Local machine

Target Environments: Multiple Docker containers simulating different environments

Simulated Environments Structure
text
Local CI Environment:
├── Jenkins Server (localhost:8080)
├── SonarQube Server (localhost:9000)
├── Artifactory Server (localhost:8081)
└── Local Docker containers for testing

Simulated Environments (via Docker):
├── Dev → SIT → UAT → Pentest → Pre-Prod → Prod
├── Each simulated with Docker containers:
│   ├── Web Servers (PHP applications)
│   ├── Nginx Reverse Proxy
│   └── Database Server (MySQL/PostgreSQL)
Local DNS Configuration
For local testing, I configured /etc/hosts to simulate domain structure:

text
127.0.0.1   ci.infradev.local
127.0.0.1   sonar.infradev.local
127.0.0.1   artifacts.infradev.local
127.0.0.1   tooling.dev.local
127.0.0.1   todo.dev.local
127.0.0.1   tooling.sit.local
127.0.0.1   todo.sit.local
🛠️ Prerequisites & Setup
Local Development Environment
Local Machine: Ubuntu 20.04/22.04 or macOS

Docker & Docker Compose: For containerized services

Java 11: Required for Jenkins and SonarQube

Python 3.x: For Ansible

Git: Version control

Local ports available: 8080, 8081, 9000, 3306, 5432

Tooling Stack (Local Configuration)
Jenkins - Local installation via Docker or native package

SonarQube 7.9.3 - Local Docker container with PostgreSQL

Artifactory OSS - Local Docker container

Ansible - Local installation for configuration management

Docker - For simulating target environments

PHP 7.4+ with dependencies - Local installation

Composer - PHP dependency management

📁 Local Ansible Inventory Structure
text
inventory/
├── ci_local
├── dev_local
├── pentest_local
├── pre-prod_local
├── prod_local
├── sit_local
└── uat_local
Local Inventory Files
CI Environment (ci_local):

ini
[jenkins]
localhost ansible_connection=local

[sonarqube]
localhost ansible_connection=local

[artifact_repository]
localhost ansible_connection=local
Development Environment (dev_local):

ini
[tooling]
localhost ansible_connection=docker container=tooling-web

[todo]
localhost ansible_connection=docker container=todo-web

[nginx]
localhost ansible_connection=docker container=nginx-proxy

[db:vars]
ansible_connection=docker
ansible_user=root

[db]
localhost ansible_connection=docker container=mysql-db
🔧 Installation & Configuration
1. Local Jenkins Setup
bash
# Install Jenkins locally
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Access Jenkins at http://localhost:8080
2. Local SonarQube Setup (Docker)
bash
# Create docker-compose.yml for SonarQube
cat > docker-compose-sonar.yml << EOF
version: '3'
services:
  sonarqube:
    image: sonarqube:7.9.3-community
    ports:
      - "9000:9000"
    environment:
      - SONARQUBE_JDBC_URL=jdbc:postgresql://db:5432/sonar
      - SONARQUBE_JDBC_USERNAME=sonar
      - SONARQUBE_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    depends_on:
      - db

  db:
    image: postgres:12
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar
      - POSTGRES_DB=sonar
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgres_data:
EOF

# Start SonarQube
docker-compose -f docker-compose-sonar.yml up -d
3. Local Artifactory Setup
bash
# Run Artifactory OSS in Docker
docker run --name artifactory \
  -d -p 8081:8081 \
  -p 8082:8082 \
  docker.bintray.io/jfrog/artifactory-oss:latest
4. Local PHP Environment Setup
bash
# Install PHP and dependencies
sudo apt install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
🚀 Pipeline Implementation
Jenkins Pipeline Configuration
Jenkinsfile Structure:

groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'inventory', defaultValue: 'dev_local', description: 'Inventory file for environment')
        string(name: 'tags', defaultValue: 'all', description: 'Ansible tags to run')
    }
    
    stages {
        stage('Initial Cleanup') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout SCM') {
            steps {
                git branch: 'main', url: 'https://github.com/yourusername/php-todo.git'
            }
        }
        
        stage('Prepare Dependencies') {
            steps {
                sh '''
                    mv .env.sample .env
                    composer install --no-interaction --prefer-dist
                    php artisan key:generate
                '''
            }
        }
        
        stage('Unit Tests') {
            steps {
                sh './vendor/bin/phpunit'
            }
        }
        
        stage('Code Analysis') {
            steps {
                sh 'phploc app/ --log-csv build/logs/phploc.csv'
            }
        }
        
        stage('SonarQube Quality Gate') {
            when { 
                branch pattern: "^develop*|^hotfix*|^release*|^main*", comparator: "REGEXP"
            }
            environment {
                scannerHome = tool 'SonarQubeScanner'
            }
            steps {
                withSonarQubeEnv('sonarqube-local') {
                    sh "${scannerHome}/bin/sonar-scanner"
                }
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Package Artifact') {
            steps {
                sh 'zip -qr php-todo.zip ${WORKSPACE}/*'
            }
        }
        
        stage('Upload to Artifactory') {
            steps {
                script {
                    def server = Artifactory.server 'artifactory-local'
                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "php-todo.zip",
                                "target": "php-todo/",
                                "props": "type=zip;status=ready"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec
                }
            }
        }
        
        stage('Deploy to Environment') {
            steps {
                sh """
                    ansible-playbook -i inventory/${params.inventory} \
                    site.yml --tags ${params.tags}
                """
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed - cleaning up workspace'
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
Local SonarQube Scanner Configuration
Create sonar-project.properties in your project root:

properties
sonar.host.url=http://localhost:9000
sonar.login=admin
sonar.password=admin
sonar.projectKey=php-todo-local
sonar.projectName=PHP Todo Local
sonar.projectVersion=1.0
sonar.sourceEncoding=UTF-8
sonar.sources=app
sonar.exclusions=**/vendor/**,**/tests/**
sonar.tests=tests
sonar.php.coverage.reportPaths=build/logs/clover.xml
sonar.php.tests.reportPath=build/logs/junit.xml
📊 Quality Gates & Testing
Local Quality Gate Implementation
SonarQube Quality Profiles: Configured "Sonar way" for PHP

Quality Gate Conditions:

Code coverage >= 80%

Duplicated lines < 3%

Maintainability rating A

Reliability rating A

Security rating A

No new bugs

No vulnerabilities

Local Testing Strategy
Unit Tests: PHPUnit with local database (SQLite for testing)

Integration Tests: Against local Docker containers

Code Quality: SonarQube analysis on local codebase

Security Scanning: Basic local security checks

🐳 Docker Simulation for Environments
Docker Compose for Environment Simulation
yaml
version: '3'
services:
  # Development Environment
  dev-web:
    image: php:7.4-apache
    ports:
      - "8080:80"
    volumes:
      - ./app:/var/www/html
    environment:
      - DB_HOST=dev-db
      - DB_NAME=homestead
      - DB_USER=homestead
      - DB_PASS=secret
  
  dev-db:
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=homestead
      - MYSQL_USER=homestead
      - MYSQL_PASSWORD=secret
  
  # SIT Environment
  sit-web:
    image: php:7.4-apache
    ports:
      - "8081:80"
    
  # UAT Environment
  uat-web:
    image: php:7.4-apache
    ports:
      - "8082:80"
🔐 Security Considerations for Local Setup
Local Firewall: Configured UFW to allow only necessary ports

Service Authentication:

Jenkins: Local user authentication

SonarQube: Default admin/admin (changed after setup)

Artifactory: Admin password set

Database Security:

Non-root database users

Strong passwords even for local setup

Database access restricted to localhost

📈 Monitoring & Logging (Local)
Local Monitoring Setup
bash
# Install monitoring tools
sudo apt install -y htop nmon net-tools

# Configure log rotation
sudo nano /etc/logrotate.d/jenkins
sudo nano /etc/logrotate.d/sonarqube

# Monitor services
sudo systemctl status jenkins
docker logs sonarqube_db
docker logs sonarqube_sonarqube_1
Local Log Locations
Jenkins: /var/log/jenkins/jenkins.log

SonarQube: Docker logs or mounted volume

Artifactory: Docker logs

Application: /var/log/apache2/ or Docker logs

🚨 Troubleshooting Local Setup
Common Issues & Solutions
Port Conflicts:

bash
# Check port usage
sudo netstat -tulpn | grep :8080
sudo netstat -tulpn | grep :9000

# Kill conflicting processes
sudo kill -9 <PID>
Docker Container Issues:

bash
# Check container status
docker ps -a
docker logs <container_name>

# Restart containers
docker-compose -f docker-compose-sonar.yml restart
Jenkins Plugin Issues:

bash
# Restart Jenkins
sudo systemctl restart jenkins

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
SonarQube Database Issues:

bash
# Check PostgreSQL connection
docker exec -it sonarqube_db psql -U sonar -d sonar

# Restart SonarQube stack
docker-compose -f docker-compose-sonar.yml down
docker-compose -f docker-compose-sonar.yml up -d
📝 Best Practices for Local Development
Version Control: All configurations in Git

Documentation: Keep README updated with local setup steps

Backup: Regular backup of Jenkins jobs and SonarQube data

Testing: Run full pipeline locally before committing changes

Security: Even locally, use strong passwords and minimal privileges

🎯 Success Criteria
The local CI/CD pipeline is considered successful when:

✅ Code commits trigger Jenkins pipelines automatically

✅ Unit tests pass with >80% code coverage

✅ SonarQube quality gates pass

✅ Artifacts are successfully uploaded to Artifactory

✅ Applications deploy to simulated environments without errors

✅ All stages complete within acceptable time limits locally

✅ Rollback procedures work when quality gates fail

🔄 Future Improvements for Local Setup
Add Performance Testing: JMeter or Gatling integration

Implement Blue-Green Deployment: For local testing

Add Security Scanning: OWASP ZAP or DependencyCheck

Implement ChatOps: Slack notifications for pipeline status

Add Dashboard: Grafana dashboard for pipeline metrics

Containerize Everything: Full Docker-based pipeline

📚 Learning Outcomes
Through this local implementation, I gained hands-on experience with:

Tool Integration: Connecting Jenkins, SonarQube, Artifactory

Pipeline Design: Creating complex multi-stage pipelines

Quality Gates: Implementing and enforcing code quality standards

Local Development: Setting up complete DevOps toolchain locally

Troubleshooting: Debugging pipeline failures and tool issues

Configuration Management: Using Ansible for local environment setup

🆘 Getting Help
For issues with the local setup:

Check service logs: journalctl -u jenkins, docker logs

Verify network connectivity between containers

Check disk space and memory usage

Ensure all prerequisites are installed

Consult documentation for each tool


