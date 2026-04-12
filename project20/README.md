
# Project 20: Kubernetes From-Ground-Up - Complete Step-by-Step Guide

## Project Objective
Build a 6-node Kubernetes cluster (3 master nodes, 3 worker nodes) from scratch on AWS EC2, with full TLS encryption, proper networking, and all control plane components manually configured.

## What I Built
- **3 Master Nodes** (Control Plane): `172.31.0.10`, `172.31.0.11`, `172.31.0.12`
- **3 Worker Nodes**: `172.31.0.20`, `172.31.0.21`, `172.31.0.22`
- **Network Load Balancer** for API server access on port 6443
- **Custom VPC** with public subnet and internet gateway
- **Complete PKI infrastructure** with self-signed CA
- **etcd cluster** (distributed key-value store)
- **All control plane components** (api-server, scheduler, controller-manager)
- **Worker components** (kubelet, kube-proxy, containerd, CNI)

---

## Phase 1: Setting Up My Local Workstation

### Step 1.1: Created Project Directory
```bash
mkdir k8s-cluster-from-ground-up
cd k8s-cluster-from-ground-up
```

### Step 1.2: Installed Required Tools

**Installed AWS CLI:**
```bash
# Downloaded and installed AWS CLI for my OS
aws configure --profile myusername
# Entered my Access Key ID, Secret Access Key, region (eu-central-1), and output format (json)
```

**Installed kubectl:**
```bash
# For Linux/Mac:
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verified installation:
kubectl version --client
```

**Installed cfssl and cfssljson:**
```bash
# For Linux:
wget https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl
wget https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/

# Verified:
cfssl version  # Should show 1.4.1 or higher
```

---

## Phase 2: Creating AWS Infrastructure

### Step 2.1: Created VPC
```bash
VPC_ID=$(aws ec2 create-vpc --cidr-block 172.31.0.0/16 --output text --query 'Vpc.VpcId')
NAME=k8s-cluster-from-ground-up
aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=${NAME}
```

### Step 2.2: Configured DNS
```bash
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'
```

### Step 2.3: Created Subnet
```bash
SUBNET_ID=$(aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block 172.31.0.0/24 --output text --query 'Subnet.SubnetId')
aws ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=${NAME}
```

### Step 2.4: Created Internet Gateway
```bash
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id ${INTERNET_GATEWAY_ID} --vpc-id ${VPC_ID}
```

### Step 2.5: Created Route Table
```bash
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id ${VPC_ID} --output text --query 'RouteTable.RouteTableId')
aws ec2 associate-route-table --route-table-id ${ROUTE_TABLE_ID} --subnet-id ${SUBNET_ID}
aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${INTERNET_GATEWAY_ID}
```

### Step 2.6: Configured Security Group
```bash
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name ${NAME} --description "Kubernetes cluster security group" --vpc-id ${VPC_ID} --output text --query 'GroupId')

# Allow etcd communication
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --ip-permissions IpProtocol=tcp,FromPort=2379,ToPort=2380,IpRanges='[{CidrIp=172.31.0.0/24}]'

# Allow NodePort services
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --ip-permissions IpProtocol=tcp,FromPort=30000,ToPort=32767,IpRanges='[{CidrIp=172.31.0.0/24}]'

# Allow API server access
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 6443 --cidr 0.0.0.0/0

# Allow SSH
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0

# Allow ICMP (ping)
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol icmp --port -1 --cidr 0.0.0.0/0
```

### Step 2.7: Created Network Load Balancer
```bash
LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer --name ${NAME} --subnets ${SUBNET_ID} --scheme internet-facing --type network --output text --query 'LoadBalancers[].LoadBalancerArn')

TARGET_GROUP_ARN=$(aws elbv2 create-target-group --name ${NAME} --protocol TCP --port 6443 --vpc-id ${VPC_ID} --target-type ip --output text --query 'TargetGroups[].TargetGroupArn')

# Registered master nodes (to be added later)
aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=172.31.0.10 Id=172.31.0.11 Id=172.31.0.12

# Created listener
aws elbv2 create-listener --load-balancer-arn ${LOAD_BALANCER_ARN} --protocol TCP --port 6443 --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN}

# Got public address
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers --load-balancer-arns ${LOAD_BALANCER_ARN} --output text --query 'LoadBalancers[].DNSName')
```

### Step 2.8: Created SSH Key Pair
```bash
mkdir -p ssh
aws ec2 create-key-pair --key-name ${NAME} --output text --query 'KeyMaterial' > ssh/${NAME}.id_rsa
chmod 600 ssh/${NAME}.id_rsa
```

### Step 2.9: Got Ubuntu AMI
```bash
IMAGE_ID=$(aws ec2 describe-images --owners 099720109477 --filters 'Name=root-device-type,Values=ebs' 'Name=architecture,Values=x86_64' 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*' | jq -r '.Images|sort_by(.Name)[-1]|.ImageId')
```

### Step 2.10: Created Master Nodes
```bash
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances --associate-public-ip-address --image-id ${IMAGE_ID} --count 1 --key-name ${NAME} --security-group-ids ${SECURITY_GROUP_ID} --instance-type t2.micro --private-ip-address 172.31.0.1${i} --user-data "name=master-${i}" --subnet-id ${SUBNET_ID} --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=${NAME}-master-${i}"
done
```

### Step 2.11: Created Worker Nodes
```bash
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances --associate-public-ip-address --image-id ${IMAGE_ID} --count 1 --key-name ${NAME} --security-group-ids ${SECURITY_GROUP_ID} --instance-type t2.micro --private-ip-address 172.31.0.2${i} --user-data "name=worker-${i}|pod-cidr=172.20.${i}.0/24" --subnet-id ${SUBNET_ID} --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=${NAME}-worker-${i}"
done
```

---

## Phase 3: Setting Up PKI Infrastructure (Certificates)

### Step 3.1: Created Certificate Authority
```bash
mkdir ca-authority && cd ca-authority
```

**Created ca-config.json:**
```json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
```

**Created ca-csr.json:**
```json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "UK",
      "L": "England",
      "O": "Kubernetes",
      "OU": "Steghub.com DEVOPS",
      "ST": "London"
    }
  ]
}
```

**Generated CA:**
```bash
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# Created: ca.pem, ca-key.pem, ca.csr
```

### Step 3.2: Generated API Server Certificate
```bash
cat > master-kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "172.31.0.10",
    "172.31.0.11",
    "172.31.0.12",
    "${KUBERNETES_PUBLIC_ADDRESS}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "UK",
      "L": "England",
      "O": "Kubernetes",
      "OU": "StegHub.com DEVOPS",
      "ST": "London"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes master-kubernetes-csr.json | cfssljson -bare master-kubernetes
```

### Step 3.3: Generated Component Certificates

**For kube-scheduler:**
```bash
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {"algo": "rsa", "size": 2048},
  "names": [{"C": "UK","L": "England","O": "system:kube-scheduler","OU": "Steghub.com DEVOPS","ST": "London"}]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
```

**For kube-proxy:**
```bash
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {"algo": "rsa", "size": 2048},
  "names": [{"C": "UK","L": "England","O": "system:node-proxier","OU": "Steghub.com DEVOPS","ST": "London"}]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
```

**For kube-controller-manager:**
```bash
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {"algo": "rsa", "size": 2048},
  "names": [{"C": "UK","L": "England","O": "system:kube-controller-manager","OU": "Steghub.com DEVOPS","ST": "London"}]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

**For each worker node's kubelet:**
```bash
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  instance_hostname="ip-172-31-0-2${i}"
  cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance_hostname}",
  "key": {"algo": "rsa", "size": 2048},
  "names": [{"C": "UK","L": "England","O": "system:nodes","OU": "Steghub.com DEVOPS","ST": "London"}]
}
EOF
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${instance_hostname} -profile=kubernetes ${instance}-csr.json | cfssljson -bare ${instance}
done
```

**For admin user:**
```bash
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {"algo": "rsa", "size": 2048},
  "names": [{"C": "UK","L": "England","O": "system:masters","OU": "Steghub.com DEVOPS","ST": "London"}]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
```

**For service accounts:**
```bash
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {"algo": "rsa", "size": 2048},
  "names": [{"C": "UK","L": "England","O": "Kubernetes","OU": "Steghub.com DEVOPS","ST": "London"}]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes service-account-csr.json | cfssljson -bare service-account
```

### Step 3.4: Distributed Certificates to Nodes

**To worker nodes:**
```bash
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  external_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${instance}" --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -i ../ssh/${NAME}.id_rsa ca.pem ${instance}-key.pem ${instance}.pem ubuntu@${external_ip}:~/
done
```

**To master nodes:**
```bash
for i in 0 1 2; do
  instance="${NAME}-master-${i}"
  external_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${instance}" --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -i ../ssh/${NAME}.id_rsa ca.pem ca-key.pem service-account-key.pem service-account.pem master-kubernetes.pem master-kubernetes-key.pem ubuntu@${external_ip}:~/
done
```

### Step 3.5: Created etcd Encryption Configuration
```bash
ETCD_ENCRYPTION_KEY=$(head -c 64 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ETCD_ENCRYPTION_KEY}
      - identity: {}
EOF

# Sent to master nodes
for i in 0 1 2; do
  instance="${NAME}-master-${i}"
  external_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${instance}" --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -i ../ssh/${NAME}.id_rsa encryption-config.yaml ubuntu@${external_ip}:~/
done
```

---

## Phase 4: Generating kubeconfig Files

### Step 4.1: Set API Server Address
```bash
KUBERNETES_API_SERVER_ADDRESS=$(aws elbv2 describe-load-balancers --load-balancer-arns ${LOAD_BALANCER_ARN} --output text --query 'LoadBalancers[].DNSName')
```

### Step 4.2: Generated Kubelet kubeconfigs
```bash
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  instance_hostname="ip-172-31-0-2${i}"
  
  kubectl config set-cluster ${NAME} --certificate-authority=ca.pem --embed-certs=true --server=https://$KUBERNETES_API_SERVER_ADDRESS:6443 --kubeconfig=${instance}.kubeconfig
  
  kubectl config set-credentials system:node:${instance_hostname} --client-certificate=${instance}.pem --client-key=${instance}-key.pem --embed-certs=true --kubeconfig=${instance}.kubeconfig
  
  kubectl config set-context default --cluster=${NAME} --user=system:node:${instance_hostname} --kubeconfig=${instance}.kubeconfig
  
  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
```

### Step 4.3: Generated kube-proxy kubeconfig
```bash
kubectl config set-cluster ${NAME} --certificate-authority=ca.pem --embed-certs=true --server=https://${KUBERNETES_API_SERVER_ADDRESS}:6443 --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials system:kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default --cluster=${NAME} --user=system:kube-proxy --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

### Step 4.4: Generated kube-controller-manager kubeconfig
```bash
kubectl config set-cluster ${NAME} --certificate-authority=ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-controller-manager.pem --client-key=kube-controller-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-context default --cluster=${NAME} --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
```

### Step 4.5: Generated kube-scheduler kubeconfig
```bash
kubectl config set-cluster ${NAME} --certificate-authority=ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-context default --cluster=${NAME} --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
```

### Step 4.6: Generated admin kubeconfig
```bash
kubectl config set-cluster ${NAME} --certificate-authority=ca.pem --embed-certs=true --server=https://${KUBERNETES_API_SERVER_ADDRESS}:6443 --kubeconfig=admin.kubeconfig
kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=admin.kubeconfig
kubectl config set-context default --cluster=${NAME} --user=admin --kubeconfig=admin.kubeconfig
kubectl config use-context default --kubeconfig=admin.kubeconfig
```

### Step 4.7: Distributed kubeconfigs to appropriate nodes
(Sent worker kubeconfigs to workers, and controller/scheduler kubeconfigs to masters)

---

## Phase 5: Bootstrapping etcd Cluster (On Each Master Node)

### Step 5.1: SSH into each master node
```bash
# For master-0
master_0_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}-master-0" --output text --query 'Reservations[].Instances[].PublicIpAddress')
ssh -i k8s-cluster-from-ground-up.id_rsa ubuntu@${master_0_ip}
```

### Step 5.2: Downloaded and installed etcd
```bash
wget -q --show-progress --https-only --timestamping "https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz"
tar -xvf etcd-v3.4.15-linux-amd64.tar.gz
sudo mv etcd-v3.4.15-linux-amd64/etcd* /usr/local/bin/
```

### Step 5.3: Configured etcd directories and certificates
```bash
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
sudo cp ca.pem master-kubernetes-key.pem master-kubernetes.pem /etc/etcd/
```

### Step 5.4: Set internal IP and node name
```bash
export INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
ETCD_NAME=$(curl -s http://169.254.169.254/latest/user-data/ | tr "|" "\n" | grep "^name" | cut -d"=" -f2)
```

### Step 5.5: Created etcd systemd service file
```bash
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-0=https://172.31.0.10:2380,master-1=https://172.31.0.11:2380,master-2=https://172.31.0.12:2380 \\
  --cert-file=/etc/etcd/master-kubernetes.pem \\
  --key-file=/etc/etcd/master-kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/master-kubernetes.pem \\
  --peer-key-file=/etc/etcd/master-kubernetes-key.pem \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Step 5.6: Started etcd service
```bash
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

### Step 5.7: Verified etcd cluster
```bash
sudo ETCDCTL_API=3 etcdctl member list --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/master-kubernetes.pem --key=/etc/etcd/master-kubernetes-key.pem
```

---

## Phase 6: Bootstrapping Control Plane (On Each Master Node)

### Step 6.1: Created Kubernetes directories
```bash
sudo mkdir -p /etc/kubernetes/config
```

### Step 6.2: Downloaded Kubernetes binaries
```bash
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl"
```

### Step 6.3: Installed binaries
```bash
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
```

### Step 6.4: Configured Kubernetes data directory
```bash
sudo mkdir -p /var/lib/kubernetes/
sudo mv ca.pem ca-key.pem master-kubernetes-key.pem master-kubernetes.pem service-account-key.pem service-account.pem encryption-config.yaml /var/lib/kubernetes/
```

### Step 6.5: Configured API Server
```bash
export INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/master-kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/master-kubernetes-key.pem \\
  --etcd-servers=https://172.31.0.10:2379,https://172.31.0.11:2379,https://172.31.0.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/master-kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/master-kubernetes-key.pem \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-account-issuer=https://${INTERNAL_IP}:6443 \\
  --service-cluster-ip-range=172.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/master-kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/master-kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Step 6.6: Configured Controller Manager
```bash
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

export AWS_METADATA="http://169.254.169.254/latest/meta-data"
export EC2_MAC_ADDRESS=$(curl -s $AWS_METADATA/network/interfaces/macs/ | head -n1 | tr -d '/')
export VPC_CIDR=$(curl -s $AWS_METADATA/network/interfaces/macs/$EC2_MAC_ADDRESS/vpc-ipv4-cidr-block/)

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=${VPC_CIDR} \\
  --cluster-name=${NAME} \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=172.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Step 6.7: Configured Scheduler
```bash
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Step 6.8: Started control plane services
```bash
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

### Step 6.9: Fixed API Server issue (Troubleshooting)
*Found the deliberate trap: The API server wouldn't start. Checked logs with `sudo journalctl -u kube-apiserver -f` and identified the issue with etcd configuration. Fixed it by correcting the `--etcd-servers` flag in the systemd file.*

### Step 6.10: Configured RBAC for kubelet authorization
```bash
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

cat <<EOF | kubectl --kubeconfig admin.kubeconfig apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

---

## Phase 7: Bootstrapping Worker Nodes (On Each Worker Node)

### Step 7.1: SSH into each worker node
```bash
# For worker-0
worker_0_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}-worker-0" --output text --query 'Reservations[].Instances[].PublicIpAddress')
ssh -i k8s-cluster-from-ground-up.id_rsa ubuntu@${worker_0_ip}
```

### Step 7.2: Installed OS dependencies
```bash
sudo apt-get update
sudo apt-get -y install socat conntrack ipset
sudo swapoff -a
```

### Step 7.3: Installed containerd (container runtime)
```bash
wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc93/runc.amd64
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.21.0/crictl-v1.21.0-linux-amd64.tar.gz
wget https://github.com/containerd/containerd/releases/download/v1.4.4/containerd-1.4.4-linux-amd64.tar.gz

mkdir containerd
tar -xvf crictl-v1.21.0-linux-amd64.tar.gz
tar -xvf containerd-1.4.4-linux-amd64.tar.gz -C containerd
sudo mv runc.amd64 runc
chmod +x crictl runc
sudo mv crictl runc /usr/local/bin/
sudo mv containerd/bin/* /bin/

sudo mkdir -p /etc/containerd/

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

### Step 7.4: Created necessary directories
```bash
sudo mkdir -p /var/lib/kubelet /var/lib/kube-proxy /etc/cni/net.d /opt/cni/bin /var/lib/kubernetes /var/run/kubernetes
```

### Step 7.5: Installed CNI plugins
```bash
wget https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz
sudo tar -xvf cni-plugins-linux-amd64-v0.9.1.tgz -C /opt/cni/bin/
```

### Step 7.6: Downloaded worker binaries
```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-proxy
wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubelet

chmod +x kubectl kube-proxy kubelet
sudo mv kubectl kube-proxy kubelet /usr/local/bin/
```

### Step 7.7: Configured pod network
```bash
POD_CIDR=$(curl -s http://169.254.169.254/latest/user-data/ | tr "|" "\n" | grep "^pod-cidr" | cut -d"=" -f2)

cat > 172-20-bridge.conf <<EOF
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

cat > 99-loopback.conf <<EOF
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF

sudo mv 172-20-bridge.conf 99-loopback.conf /etc/cni/net.d/
```

### Step 7.8: Configured kubelet
```bash
NAME=k8s-cluster-from-ground-up
WORKER_NAME=${NAME}-$(curl -s http://169.254.169.254/latest/user-data/ | tr "|" "\n" | grep "^name" | cut -d"=" -f2)

sudo mv ${WORKER_NAME}-key.pem ${WORKER_NAME}.pem /var/lib/kubelet/
sudo mv ${WORKER_NAME}.kubeconfig /var/lib/kubelet/kubeconfig
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
sudo mv ca.pem /var/lib/kubernetes/

cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
resolvConf: "/etc/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${WORKER_NAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${WORKER_NAME}-key.pem"
EOF

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service
[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --cluster-domain=cluster.local \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

### Step 7.9: Configured kube-proxy
```bash
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "172.31.0.0/16"
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

### Step 7.10: Started worker services
```bash
sudo systemctl daemon-reload
sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl start containerd kubelet kube-proxy
```

---

## Phase 8: Verification

### Step 8.1: Checked cluster from master node
```bash
kubectl cluster-info --kubeconfig admin.kubeconfig
kubectl get namespaces --kubeconfig admin.kubeconfig
kubectl get componentstatuses --kubeconfig admin.kubeconfig
kubectl get nodes --kubeconfig admin.kubeconfig
```

### Step 8.2: Verified all nodes are ready
```bash
kubectl get nodes --kubeconfig admin.kubeconfig
# Output showed all 3 worker nodes in READY state
```

### Step 8.3: Tested API server access
```bash
curl --cacert /var/lib/kubernetes/ca.pem https://$INTERNAL_IP:6443/version
```

---

## Key Troubleshooting I Encountered

1. **API Server wouldn't start**: Used `journalctl -u kube-apiserver -f` to find the etcd connection issue. Fixed the `--etcd-servers` flag in the systemd unit file.

2. **Kubelet wouldn't start on workers**: Checked logs with `journalctl -u kubelet -f`. Found certificate issues and ensured correct hostnames in certificate generation.

3. **Nodes not joining cluster**: Verified kubeconfig files were correctly generated and distributed to each worker node with proper certificates.

4. **CNI network issues**: Ensured the bridge configuration was correct and the `POD_CIDR` didn't overlap with the VPC CIDR.

## Final Result

Successfully built a fully functional 6-node Kubernetes cluster with:
- 3 master nodes running all control plane components
- 3 worker nodes running kubelet and kube-proxy
- TLS encryption for all component communication
- etcd cluster for distributed state storage
- Container networking via CNI plugins
- Load balancer for API server high availability

**This cluster is now ready for application deployment in future projects!**