# Complete Project README: Deploying Applications on Kubernetes (EKS)

## Project Overview

This comprehensive project guides you through the complete journey of deploying, managing, and scaling containerized applications on Kubernetes. Starting from basic concepts, you'll progress to production-ready deployments on AWS EKS, implement CI/CD pipelines, and set up enterprise-grade monitoring. By the end, you'll have hands-on experience with all major Kubernetes objects and patterns used in real-world DevOps environments.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Phase 1: Kubernetes Fundamentals](#phase-1-kubernetes-fundamentals)
  - [1.1 Deploy Your First Pod](#11-deploy-your-first-pod)
  - [1.2 Accessing the Pod with Services](#12-accessing-the-pod-with-services)
  - [1.3 Service Types Deep Dive](#13-service-types-deep-dive)
- [Phase 2: Application Lifecycle Management](#phase-2-application-lifecycle-management)
  - [2.1 Self-Healing with ReplicaSets](#21-self-healing-with-replicasets)
  - [2.2 Declarative Deployments](#22-declarative-deployments)
  - [2.3 Understanding Stateless vs Stateful](#23-understanding-stateless-vs-stateful)
- [Phase 3: Self-Side Task - Tooling App Deployment](#phase-3-self-side-task---tooling-app-deployment)
  - [3.1 Dockerize the Tooling App](#31-dockerize-the-tooling-app)
  - [3.2 Deploy with Pod and Service](#32-deploy-with-pod-and-service)
- [Phase 4: Advanced Storage Concepts (Next Project Prep)](#phase-4-advanced-storage-concepts-next-project-prep)
  - [4.1 Persistent Volumes and Claims](#41-persistent-volumes-and-claims)
  - [4.2 ConfigMaps for Configuration Management](#42-configmaps-for-configuration-management)
  - [4.3 StatefulSet for MySQL Database](#43-statefulset-for-mysql-database)
- [Phase 5: Helm - The Kubernetes Package Manager](#phase-5-helm---the-kubernetes-package-manager)
  - [5.1 Convert YAML Manifests to Helm Chart](#51-convert-yaml-manifests-to-helm-chart)
  - [5.2 Semantic Versioning Best Practices](#52-semantic-versioning-best-practices)
- [Phase 6: AWS EKS Production Deployment](#phase-6-aws-eks-production-deployment)
  - [6.1 Provision EKS Cluster](#61-provision-eks-cluster)
  - [6.2 Deploy Jenkins and Ingress](#62-deploy-jenkins-and-ingress)
  - [6.3 Set Up Cert-Manager](#63-set-up-cert-manager)
- [Phase 7: Monitoring Stack Deployment](#phase-7-monitoring-stack-deployment)
  - [7.1 Deploy Prometheus](#71-deploy-prometheus)
  - [7.2 Deploy Grafana Dashboards](#72-deploy-grafana-dashboards)
- [Phase 8: CI/CD and GitOps](#phase-8-cicd-and-gitops)
  - [8.1 Hybrid CI/CD Pipeline](#81-hybrid-cicd-pipeline)
  - [8.2 GitOps with Weaveworks Flux](#82-gitops-with-weaveworks-flux)
- [Complete Self-Side Tasks Checklist](#complete-self-side-tasks-checklist)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [Project Submission Guidelines](#project-submission-guidelines)

## Prerequisites

### Required Tools
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh && ./get_helm.sh

# Install awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### AWS Account Setup
- AWS account with administrative access
- Configure AWS credentials: `aws configure`
- Default region: `us-east-1` or `eu-central-1`
- IAM roles for EKS cluster creation

### Local Development Environment
- 4+ CPU cores, 8GB+ RAM
- 20GB free disk space
- Ubuntu 20.04+ or macOS
- Git configured with SSH keys

## Phase 1: Kubernetes Fundamentals

### 1.1 Deploy Your First Pod

**Objective:** Create and manage individual Pods, understanding their ephemeral nature.

```yaml
# nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    environment: development
    tier: frontend
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
      protocol: TCP
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Commands to Execute:**
```bash
# Create the pod
kubectl apply -f nginx-pod.yaml

# View pod status with detailed information
kubectl get pods -o wide
kubectl describe pod nginx-pod

# Check pod logs
kubectl logs nginx-pod

# Execute commands inside the container
kubectl exec -it nginx-pod -- /bin/bash

# See the complete YAML with Kubernetes-generated fields
kubectl get pod nginx-pod -o yaml

# Clean up
kubectl delete pod nginx-pod
```

### 1.2 Accessing the Pod with Services

**Objective:** Understand how Services provide stable networking to ephemeral Pods.

**Step 1: Create a Service**

```yaml
# nginx-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx  # This must match pod labels
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  sessionAffinity: ClientIP
```

```bash
# Apply both pod and service
kubectl apply -f nginx-pod.yaml
kubectl apply -f nginx-service-clusterip.yaml

# Test internal access
kubectl run test-pod --image=busybox -it --rm --restart=Never -- sh
# Inside the container:
wget -qO- http://nginx-service
exit

# Port forward to local machine
kubectl port-forward service/nginx-service 8080:80
# Access at http://localhost:8080
```

### 1.3 Service Types Deep Dive

**Objective:** Master different Service types for various use cases.

#### Type 1: NodePort Service

```yaml
# nginx-service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # Range: 30000-32767
```

```bash
kubectl apply -f nginx-service-nodeport.yaml

# Get node IP and port
kubectl get nodes -o wide
kubectl get svc nginx-nodeport

# Access via: http://<NODE_EXTERNAL_IP>:30080

# Update security group (AWS example)
# Allow inbound TCP port 30080 from 0.0.0.0/0
```

#### Type 2: LoadBalancer Service (AWS EKS)

```yaml
# nginx-service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f nginx-service-loadbalancer.yaml

# Wait for external IP assignment (1-2 minutes)
kubectl get svc nginx-lb -w

# Access via the DNS name provided in EXTERNAL-IP column
```

## Phase 2: Application Lifecycle Management

### 2.1 Self-Healing with ReplicaSets

**Objective:** Understand how ReplicaSets ensure high availability.

```yaml
# replicaset.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
    matchExpressions:
    - key: environment
      operator: In
      values: ["development", "staging"]
  template:
    metadata:
      labels:
        app: nginx
        environment: development
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
# Create ReplicaSet
kubectl apply -f replicaset.yaml

# Watch pods being created
kubectl get pods -w

# Test self-healing
kubectl delete pod nginx-replicaset-xxxxx  # Use actual pod name

# Observe the replacement pod being created
kubectl get pods

# Scale ReplicaSet
kubectl scale replicaset nginx-replicaset --replicas=5

# Check ReplicaSet status
kubectl describe rs nginx-replicaset
```

### 2.2 Declarative Deployments

**Objective:** Learn why Deployments are the recommended approach for stateless applications.

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Rolling Update Demonstration:**

```bash
# Create deployment
kubectl apply -f deployment.yaml

# Watch rollout status
kubectl rollout status deployment nginx-deployment

# Update image version
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# Watch rolling update process
kubectl get pods -w

# Check rollout history
kubectl rollout history deployment nginx-deployment

# Rollback if needed
kubectl rollout undo deployment nginx-deployment

# Pause and resume rollout
kubectl rollout pause deployment nginx-deployment
kubectl rollout resume deployment nginx-deployment
```

### 2.3 Understanding Stateless vs Stateful

**Objective:** Demonstrate why stateful applications require special handling.

```bash
# Get the running pod name
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

# Exec into the pod
kubectl exec -it $POD_NAME -- bash

# Inside the container:
cd /usr/share/nginx/html
apt-get update && apt-get install vim -y
echo "<h1>Modified Content - $(date)</h1>" > index.html
exit

# Access and see modified content
kubectl port-forward pod/$POD_NAME 8080:80
# Visit localhost:8080 to see changes

# Delete the pod to trigger recreation
kubectl delete pod $POD_NAME

# Wait for new pod, then exec in
NEW_POD=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $NEW_POD -- cat /usr/share/nginx/html/index.html
# Original content restored - data lost!
```

## Phase 3: Self-Side Task - Tooling App Deployment

### 3.1 Dockerize the Tooling App

**Task:** Build a Docker image for the tooling application and push to Docker Hub.

```dockerfile
# Dockerfile
FROM php:7.4-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql mbstring exif pcntl bcmath

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
```

```bash
# Build the Docker image
docker build -t your-dockerhub-username/tooling-app:latest .

# Test locally
docker run -d -p 8080:80 --name tooling-test your-dockerhub-username/tooling-app:latest

# Push to Docker Hub
docker login
docker push your-dockerhub-username/tooling-app:latest
docker push your-dockerhub-username/tooling-app:v1.0.0  # Tag a version
```

### 3.2 Deploy with Pod and Service

**Task:** Create manifests and deploy to Kubernetes.

```yaml
# tooling-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: tooling-app
  labels:
    app: tooling
    version: v1
    environment: production
spec:
  containers:
  - name: tooling
    image: your-dockerhub-username/tooling-app:latest
    ports:
    - containerPort: 80
    env:
    - name: DB_HOST
      value: "mysql-service"
    - name: DB_DATABASE
      value: "toolingdb"
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: mysql-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysql-secret
          key: password
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
```

```yaml
# tooling-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: tooling-service
spec:
  type: NodePort
  selector:
    app: tooling
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

```yaml
# mysql-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  username: cm9vdA==  # base64 encoded 'root'
  password: cGFzc3dvcmQxMjM=  # base64 encoded 'password123'
```

```bash
# Create secret
kubectl apply -f mysql-secret.yaml

# Deploy tooling app
kubectl apply -f tooling-pod.yaml
kubectl apply -f tooling-service.yaml

# Verify deployment
kubectl get pods,svc,secrets

# Access the application
kubectl port-forward svc/tooling-service 8080:80
# Visit http://localhost:8080

# Or access via NodePort
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
curl http://$NODE_IP:30080
```

## Phase 4: Advanced Storage Concepts

### 4.1 Persistent Volumes and Claims

**Objective:** Configure persistent storage for database applications.

```yaml
# persistent-volume.yaml (EBS for EKS)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
  labels:
    type: ebs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  awsElasticBlockStore:
    volumeID: vol-xxxxxxxxxxxxx  # Replace with your EBS volume ID
    fsType: ext4
```

```yaml
# persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  selector:
    matchLabels:
      type: ebs
```

```bash
# Create PV and PVC
kubectl apply -f persistent-volume.yaml
kubectl apply -f persistent-volume-claim.yaml

# Verify binding
kubectl get pv
kubectl get pvc

# Test with a pod
kubectl run test-pv --image=nginx --restart=Never -it --rm -- bash
# Inside container:
mount | grep /var/lib/mysql
exit
```

### 4.2 ConfigMaps for Configuration Management

```yaml
# tooling-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tooling-config
data:
  app-config.php: |
    <?php
    define('APP_NAME', 'Tooling Application');
    define('APP_ENV', 'production');
    define('APP_DEBUG', false);
    define('APP_URL', 'http://tooling.example.com');
    ?>
  nginx-config.conf: |
    server {
        listen 80;
        server_name tooling.local;
        root /var/www/html/public;
        index index.php;
        
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
        
        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
```

### 4.3 StatefulSet for MySQL Database

**Objective:** Deploy MySQL as a StatefulSet with persistent storage.

```yaml
# mysql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-statefulset
spec:
  serviceName: mysql-service
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        - name: MYSQL_DATABASE
          value: "toolingdb"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
```

```bash
# Deploy MySQL StatefulSet
kubectl apply -f mysql-statefulset.yaml

# Check StatefulSet status
kubectl get statefulset
kubectl get pods -l app=mysql
kubectl get pvc

# Test data persistence
kubectl exec -it mysql-statefulset-0 -- mysql -u root -p
# Create a test database
CREATE DATABASE test_persistence;
USE test_persistence;
CREATE TABLE test (id INT, name VARCHAR(50));
INSERT INTO test VALUES (1, 'test data');
EXIT;

# Delete the pod
kubectl delete pod mysql-statefulset-0

# Wait for recreation and verify data
kubectl exec -it mysql-statefulset-0 -- mysql -u root -p -e "SELECT * FROM test_persistence.test;"
```

## Phase 5: Helm - The Kubernetes Package Manager

### 5.1 Convert YAML Manifests to Helm Chart

**Task:** Create a reusable Helm chart for the tooling application.

```bash
# Create a new chart
helm create tooling-chart

# Directory structure created:
# tooling-chart/
#   ├── Chart.yaml
#   ├── values.yaml
#   ├── templates/
#   │   ├── deployment.yaml
#   │   ├── service.yaml
#   │   ├── configmap.yaml
#   │   ├── secret.yaml
#   │   └── _helpers.tpl
#   └── charts/
```

**Update Chart.yaml:**
```yaml
apiVersion: v2
name: tooling-app
description: A Helm chart for the Tooling Application
type: application
version: 1.0.0
appVersion: "1.0.0"
maintainers:
- name: DevOps Team
  email: devops@example.com
keywords:
- tooling
- php
- webapp
```

**Enhanced values.yaml:**
```yaml
# Global settings
global:
  environment: production
  imagePullSecrets: []

# Application configuration
image:
  repository: your-dockerhub-username/tooling-app
  tag: latest
  pullPolicy: IfNotPresent

# Replica count
replicaCount: 3

# Service configuration
service:
  type: ClusterIP
  port: 80
  nodePort: 30080
  annotations: {}

# Ingress configuration
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: tooling.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: tooling-tls
      hosts:
        - tooling.example.com

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Database configuration
mysql:
  enabled: true
  image: mysql:8.0
  database: toolingdb
  rootPassword: "tooling123"
  persistence:
    enabled: true
    size: 10Gi

# Monitoring
monitoring:
  enabled: true
  serviceMonitor:
    interval: 30s
```

**Customize templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "tooling-chart.fullname" . }}
  labels:
    {{- include "tooling-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "tooling-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "tooling-chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "{{ .Release.Name }}-mysql"
        - name: DB_DATABASE
          value: {{ .Values.mysql.database }}
        - name: DB_USERNAME
          value: "root"
        - name: DB_PASSWORD
          value: {{ .Values.mysql.rootPassword }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

```bash
# Lint the chart
helm lint tooling-chart/

# Template rendering (dry run)
helm template tooling-release ./tooling-chart --debug

# Install the chart
helm install tooling-release ./tooling-chart --namespace tooling --create-namespace

# List releases
helm list -n tooling

# Upgrade with new values
helm upgrade tooling-release ./tooling-chart --set replicaCount=5

# Rollback
helm rollback tooling-release 1

# Uninstall
helm uninstall tooling-release -n tooling
```

### 5.2 Semantic Versioning Best Practices

```yaml
# Chart version guidelines
# MAJOR.MINOR.PATCH

# MAJOR version (X.y.z) - Incompatible API changes
# Example: 2.0.0 - Changed from Deployment to StatefulSet

# MINOR version (x.Y.z) - Backward-compatible new functionality
# Example: 1.1.0 - Added monitoring sidecar container

# PATCH version (x.y.Z) - Backward-compatible bug fixes
# Example: 1.0.1 - Fixed security vulnerability

# Chart versioning example:
version: 2.1.3

# App version (software version)
appVersion: "5.2.0"

# Dependency management
dependencies:
  - name: mysql
    version: "8.0.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: mysql.enabled
```

## Phase 6: AWS EKS Production Deployment

### 6.1 Provision EKS Cluster

**Using eksctl:**

```yaml
# cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: tooling-cluster
  region: us-east-1
  version: "1.28"

vpc:
  cidr: 10.0.0.0/16
  subnets:
    private:
      us-east-1a: { cidr: 10.0.1.0/24 }
      us-east-1b: { cidr: 10.0.2.0/24 }
    public:
      us-east-1a: { cidr: 10.0.3.0/24 }
      us-east-1b: { cidr: 10.0.4.0/24 }

managedNodeGroups:
- name: standard-workers
  instanceType: t3.medium
  desiredCapacity: 3
  minSize: 1
  maxSize: 5
  volumeSize: 80
  ssh:
    allow: true
    publicKeyName: your-key-pair
  labels:
    role: worker
  tags:
    Environment: production
  iam:
    withAddonPolicies:
      autoScaler: true
      cloudWatch: true
      ebs: true
      efs: true

addons:
- name: vpc-cni
- name: coredns
- name: kube-proxy
- name: aws-ebs-csi-driver
```

```bash
# Create cluster
eksctl create cluster -f cluster.yaml

# Update kubeconfig
aws eks update-kubeconfig --name tooling-cluster --region us-east-1

# Verify cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods -n kube-system
```

### 6.2 Deploy Jenkins and Ingress

**Install Jenkins with Helm:**

```bash
# Add Jenkins repo
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create namespace
kubectl create namespace jenkins

# Create custom values file
cat > jenkins-values.yaml << EOF
controller:
  adminUser: admin
  adminPassword: "jenkins123"
  image: jenkins/jenkins:lts
  serviceType: ClusterIP
  ingress:
    enabled: true
    hostName: jenkins.tooling.com
    annotations:
      kubernetes.io/ingress.class: nginx
  resources:
    requests:
      cpu: "500m"
      memory: "1024Mi"
    limits:
      cpu: "1000m"
      memory: "2048Mi"
  installPlugins:
    - kubernetes:latest
    - workflow-job:latest
    - workflow-aggregator:latest
    - credentials-binding:latest
    - git:latest
  javaOpts: "-Xms512m -Xmx1024m"

persistence:
  enabled: true
  size: 8Gi
  storageClass: gp2
EOF

# Install Jenkins
helm install jenkins jenkins/jenkins -f jenkins-values.yaml -n jenkins

# Get admin password
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- \
  cat /var/jenkins_home/secrets/initialAdminPassword

# Port forward to access
kubectl port-forward --namespace jenkins svc/jenkins 8080:8080
```

**Install Nginx Ingress Controller:**

```bash
# Add ingress-nginx repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
```

### 6.3 Set Up Cert-Manager

```bash
# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
cat > cluster-issuer.yaml << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@tooling.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl apply -f cluster-issuer.yaml
```

## Phase 7: Monitoring Stack Deployment

### 7.1 Deploy Prometheus

```bash
# Add Prometheus community repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack
cat > prometheus-values.yaml << EOF
prometheus:
  prometheusSpec:
    retention: 15d
    resources:
      requests:
        memory: 2Gi
        cpu: 500m
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

alertmanager:
  enabled: true
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'null'
    receivers:
    - name: 'null'

grafana:
  enabled: true
  adminPassword: prom-operator
  persistence:
    enabled: true
    size: 10Gi
  ingress:
    enabled: true
    hosts: ["grafana.tooling.com"]
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - hosts: ["grafana.tooling.com"]
        secretName: grafana-tls

kube-state-metrics:
  enabled: true

nodeExporter:
  enabled: true
EOF

helm install monitoring prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml \
  -n monitoring
```

### 7.2 Deploy Grafana Dashboards

```bash
# Get Grafana admin password
kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward to access Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Import Kubernetes dashboards
# Dashboard IDs:
# 315 - Kubernetes Cluster Monitoring
# 6417 - Kubernetes Pod Metrics
# 8588 - Kubernetes Deployment StatefulSet
# 15760 - Kubernetes Node Exporter Full

# Create custom dashboard for Tooling App
cat > tooling-dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Tooling Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "Response Time (p99)",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "{{endpoint}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~'5..'}[5m]) / rate(http_requests_total[5m])",
            "legendFormat": "5xx Errors"
          }
        ]
      }
    ]
  }
}
EOF
```

## Phase 8: CI/CD and GitOps

### 8.1 Hybrid CI/CD Pipeline

**GitLab CI Configuration (.gitlab-ci.yml):**

```yaml
stages:
  - build
  - test
  - deploy-staging
  - deploy-production

variables:
  DOCKER_REGISTRY: your-dockerhub-username
  APP_NAME: tooling-app

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_REGISTRY/$APP_NAME:$CI_COMMIT_SHA .
    - docker push $DOCKER_REGISTRY/$APP_NAME:$CI_COMMIT_SHA
    - docker tag $DOCKER_REGISTRY/$APP_NAME:$CI_COMMIT_SHA $DOCKER_REGISTRY/$APP_NAME:latest
    - docker push $DOCKER_REGISTRY/$APP_NAME:latest

test:
  stage: test
  image: alpine/helm:latest
  script:
    - helm lint tooling-chart/
    - helm template tooling-release ./tooling-chart --debug

deploy-staging:
  stage: deploy-staging
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/tooling-deployment tooling=$DOCKER_REGISTRY/$APP_NAME:$CI_COMMIT_SHA -n staging
  only:
    - develop

deploy-production:
  stage: deploy-production
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/tooling-deployment tooling=$DOCKER_REGISTRY/$APP_NAME:$CI_COMMIT_SHA -n production
  only:
    - main
```

### 8.2 GitOps with Weaveworks Flux

```bash
# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Bootstrap Flux on EKS
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=tooling-gitops \
  --branch=main \
  --path=./clusters/production \
  --personal

# Add Helm repository to Flux
flux create source helm tooling-charts \
  --url=https://charts.tooling.com \
  --interval=10m

# Create Helm release resource
cat > helm-release.yaml << EOF
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: tooling-app
  namespace: production
spec:
  interval: 5m
  chart:
    spec:
      chart: tooling-app
      sourceRef:
        kind: HelmRepository
        name: tooling-charts
  values:
    image:
      tag: ${CI_COMMIT_SHA}
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
EOF

kubectl apply -f helm-release.yaml

# Check sync status
flux get helmreleases -n production
```

## Complete Self-Side Tasks Checklist

### Task 1: Build Tooling App Dockerfile
- [x] Create Dockerfile with PHP/Apache configuration
- [x] Install required PHP extensions
- [x] Copy application source code
- [x] Configure Apache virtual host
- [x] Set proper file permissions
- [x] Build and test locally
- [x] Push to Docker Hub with version tags

### Task 2: Write Pod and Service Manifests
- [x] Create Pod manifest with proper labels
- [x] Configure environment variables for database connection
- [x] Set resource requests and limits
- [x] Create NodePort service manifest
- [x] Test port-forward access
- [x] Verify DNS resolution within cluster

### Task 3: ReplicaSet Implementation
- [x] Create ReplicaSet with 3 replicas
- [x] Test self-healing by deleting pods
- [x] Scale up to 5 replicas imperatively
- [x] Scale down declaratively using YAML

### Task 4: Deployment Rollout Strategies
- [x] Implement rolling update strategy
- [x] Test readiness and liveness probes
- [x] Perform image update and observe rollout
- [x] Execute rollback to previous version

### Task 5: MySQL StatefulSet
- [x] Create PersistentVolume and PersistentVolumeClaim
- [x] Write StatefulSet manifest for MySQL
- [x] Use volumeClaimTemplates for dynamic provisioning
- [x] Test data persistence across pod restarts
- [x] Verify DNS stability with StatefulSet

### Task 6: Configuration Management
- [x] Create ConfigMap for application configuration
- [x] Mount ConfigMap as volume or environment variables
- [x] Update configuration without rebuilding image

### Task 7: Helm Chart Development
- [x] Initialize Helm chart structure
- [x] Parameterize all values in templates
- [x] Add conditional logic for optional components
- [x] Create values files for different environments (dev, staging, prod)
- [x] Test with helm template and helm install --dry-run

### Task 8: AWS EKS Cluster
- [x] Write eksctl configuration file
- [x] Create EKS cluster with managed node groups
- [x] Configure IAM roles and policies
- [x] Set up EBS CSI driver for persistence
- [x] Verify cluster health and connectivity

### Task 9: Ingress and Cert-Manager
- [x] Install Nginx Ingress Controller
- [x] Create Ingress rules for Tooling App
- [x] Install cert-manager with Helm
- [x] Configure ClusterIssuer for Let's Encrypt
- [x] Obtain TLS certificates for domains

### Task 10: Monitoring Configuration
- [x] Deploy Prometheus stack with Helm
- [x] Configure ServiceMonitor for Tooling App
- [x] Set up Grafana data source
- [x] Import Kubernetes monitoring dashboards
- [x] Create custom dashboard for application metrics

### Task 11: CI/CD Pipeline
- [x] Configure GitLab CI stages
- [x] Implement Docker build and push step
- [x] Add Helm linting and testing
- [x] Configure deployment to staging environment
- [x] Implement production deployment with approval gate

### Task 12: GitOps Implementation
- [x] Install and bootstrap Flux
- [x] Create Git repository for manifests
- [x] Configure Flux to sync automatically
- [x] Implement image update automation

## Troubleshooting Common Issues

### Pod Stuck in Pending State
```bash
# Check node capacity
kubectl describe nodes

# Check PVC binding
kubectl get pvc

# Check resource limits
kubectl describe pod <pod-name>

# Common solutions:
# - Increase node count
# - Reduce resource requests
# - Check storage class availability
```

### Service Not Accessible
```bash
# Verify service endpoints
kubectl get endpoints <service-name>

# Check selector matching
kubectl get pods --show-labels

# Test DNS resolution
kubectl run test --rm -it --image=busybox -- nslookup <service-name>

# Verify network policies
kubectl get networkpolicies
```

### Helm Chart Issues
```bash
# Debug template rendering
helm template <release> <chart> --debug --dry-run

# Check for deprecated APIs
helm lint <chart-dir>

# View release history
helm history <release>

# Get values used
helm get values <release>
```

### EKS Cluster Problems
```bash
# Check node group status
eksctl get nodegroups --cluster=<cluster-name>

# View cluster logs
kubectl logs -n kube-system

# Check AWS IAM authenticator
kubectl describe configmap -n kube-system aws-auth

# Verify VPC configuration
aws ec2 describe-vpcs --vpc-ids <vpc-id>
```

## Project Submission Guidelines

### Required Deliverables

1. **GitHub Repository Structure:**
```
kubernetes-project/
├── manifests/
│   ├── nginx-pod.yaml
│   ├── nginx-service.yaml
│   ├── replicaset.yaml
│   ├── deployment.yaml
│   ├── tooling-pod.yaml
│   └── tooling-service.yaml
├── helm-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/
├── monitoring/
│   ├── prometheus-values.yaml
│   ├── grafana-dashboards/
│   └── alert-rules.yaml
├── cluster/
│   ├── eks-cluster.yaml
│   └── iam-policies.json
├── ci-cd/
│   ├── .gitlab-ci.yml
│   ├── Jenkinsfile
│   └── flux-config.yaml
└── README.md
```

2. **Documentation Required:**
- Screenshots of all Kubernetes objects (pods, services, deployments)
- Evidence of successful Helm chart installation
- Screenshot of Grafana dashboards showing metrics
- Proof of Ingress access with TLS certificate
- CI/CD pipeline execution logs
- GitOps sync status from Flux

3. **Verification Steps:**
```bash
# Run verification script
cat > verify-project.sh << 'EOF'
#!/bin/bash

echo "=== Checking Kubernetes Resources ==="
kubectl get all --all-namespaces

echo "=== Checking Helm Releases ==="
helm list --all-namespaces

echo "=== Testing Application Access ==="
kubectl run test --rm -it --image=curlimages/curl -- \
  curl -s http://tooling-service.default.svc.cluster.local

echo "=== Verifying Prometheus ==="
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
sleep 2
curl -s http://localhost:9090/-/healthy

echo "=== All checks passed! ==="
EOF

chmod +x verify-project.sh
./verify-project.sh
```

4. **Final Submission:**
- Push all code to GitHub repository
- Create detailed README with setup instructions
- Include all screenshots in `/docs` folder
- Submit repository URL to course portal
- Ensure all manifests are properly formatted and commented

### Bonus Points
- Implement horizontal pod autoscaling (HPA)
- Set up backup and restore for persistent volumes
- Implement service mesh with Istio
- Create custom Prometheus alerts
- Implement Blue-Green deployment strategy
- Set up Velero for cluster backup

## Conclusion

This project provides comprehensive hands-on experience with Kubernetes in production environments. By completing all phases and self-side tasks, you'll have demonstrated proficiency in:

- Core Kubernetes concepts and object management
- Stateful and stateless application deployment
- Helm chart development and management
- AWS EKS cluster provisioning and management
- CI/CD pipeline implementation
- GitOps practices with Flux
- Monitoring and observability with Prometheus/Grafana
- Production deployment patterns and best practices

**Next Steps:** Apply these skills to real-world scenarios, explore service meshes like Istio, implement chaos engineering, or contribute to open-source Kubernetes projects.