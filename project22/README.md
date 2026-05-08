# Detailed README: Kubernetes Stateful Applications Project

## Project Overview

This project demonstrates how to implement stateful applications in Kubernetes by understanding and working with Volumes, PersistentVolumes (PV), PersistentVolumeClaims (PVC), and ConfigMaps. You will learn to persist data beyond pod lifecycles and manage configuration files effectively.

## Prerequisites

Before starting this project, ensure you have:

1. **An existing EKS cluster** - This is mentioned at the beginning of the assignment
2. **kubectl configured** - Working access to your EKS cluster
3. **AWS CLI installed and configured** - For EBS volume operations
4. **Basic understanding of Kubernetes concepts** - Pods, Deployments, Services

---

## Task 1: Run Nginx Deployment Without Volume (Baseline)

### Objective
Verify that without persistence, container data is ephemeral.

### Steps

1. **Create the initial deployment manifest**

```bash
sudo cat <<EOF | sudo tee ./nginx-pod.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
EOF
```

2. **Apply the deployment**

```bash
kubectl apply -f nginx-pod.yaml
```

3. **Verify pods are running**

```bash
kubectl get pods
```
Expected output shows 3 pods with STATUS "Running".

4. **Check pod logs**

```bash
# Get pod names first
kubectl get pods

# Check logs of a specific pod (replace pod name with yours)
kubectl logs nginx-deployment-6fdcffd8fc-thcfp
```

5. **Exec into a pod and explore**

```bash
# Replace pod name with your actual pod name
kubectl exec -it nginx-deployment-6fdcffd8fc-thcfp -- bash
```

Once inside the container:
```bash
# Navigate to nginx configuration directory
cd /etc/nginx/conf.d

# List files
ls -la

# View default configuration
cat default.conf

# Exit the container
exit
```

### Expected Learning
You'll observe that any data written inside the container disappears when the pod terminates or restarts.

---

## Task 2: Create EBS Volume for Persistence

### Objective
Manually create an AWS EBS volume that will be attached to your pod.

### Steps

1. **Find which node your pod is running on**

```bash
# Get pod details with node information
kubectl get pods -o wide
```

Example output:
```
NAME                                READY   STATUS    RESTARTS   AGE   IP           NODE
nginx-deployment-6fdcffd8fc-thcfp   1/1     Running   0          64m   10.0.3.159   ip-10-0-3-233.eu-west-2.compute.internal
```

2. **Get the availability zone of that node**

```bash
# Replace node name with your actual node name
kubectl describe node ip-10-0-3-233.eu-west-2.compute.internal
```

Look for the `topology.kubernetes.io/zone` label in the output. For example: `eu-west-2c`

3. **Create an EBS volume in the same AZ**

Via AWS CLI:
```bash
aws ec2 create-volume \
    --availability-zone eu-west-2c \
    --size 10 \
    --volume-type gp2
```

Note the `VolumeId` from the response (e.g., `vol-0e194e56f1b5302ee`)

4. **Update the deployment with EBS volume**

```bash
sudo cat <<EOF | sudo tee ./nginx-pod.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
      volumes:
      - name: nginx-volume
        # Replace with your volume ID
        awsElasticBlockStore:
          volumeID: "vol-0e194e56f1b5302ee"
          fsType: ext4
EOF
```

5. **Apply the updated configuration**

```bash
kubectl apply -f nginx-pod.yaml
```

6. **Observe pod replacement**

```bash
kubectl get pods -w
```
You'll see the old pod terminating and a new one starting.

7. **Inspect the new pod**

```bash
kubectl describe pod <new-pod-name>
kubectl describe deployment nginx-deployment
```

### Important Note
The volume is created but NOT yet mounted to a specific filesystem. Data written to `/usr/share/nginx/html` will still be ephemeral.

---

## Task 3: Mount the Volume to Container Filesystem

### Objective
Properly mount the EBS volume to persist website data.

### Steps

1. **Update deployment to include volumeMounts**

```bash
cat <<EOF | tee ./nginx-pod.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-volume
        awsElasticBlockStore:
          volumeID: "vol-07b537651bbe68be0"  # Replace with your volume ID
          fsType: ext4
EOF
```

2. **Apply the configuration**

```bash
kubectl apply -f nginx-pod.yaml
```

3. **Test the endpoint**

First, expose the deployment:
```bash
kubectl port-forward deployment/nginx-deployment 8080:80
```

Open browser to `http://localhost:8080`

**Expected Result:** You'll likely see a 403 error because mounting a volume to a directory that contains data erases the existing data.

### Key Learning
When you mount a volume to a directory that already contains files (like the default nginx HTML files), those files become inaccessible. This is why you get a 403 error.

---

## Task 4: Implement PersistentVolumeClaim (PVC) - Dynamic Provisioning

### Objective
Use PVC for dynamic volume provisioning, eliminating manual volume creation.

### Steps

1. **Check existing StorageClass**

```bash
kubectl get storageclass
```

Expected output showing `gp2 (default)` with `WaitForFirstConsumer` binding mode.

2. **Create PVC manifest**

```bash
cat <<EOF | tee ./pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-volume-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: gp2
EOF
```

3. **Apply the PVC**

```bash
kubectl apply -f pvc.yaml
```

4. **Check PVC status**

```bash
kubectl get pvc
```

Initial status will be `Pending` with message: "waiting for first consumer to be created before binding"

5. **Troubleshoot the pending status**

```bash
kubectl describe pvc nginx-volume-claim
```

Look for the `WaitForFirstConsumer` event - this is expected behavior.

6. **Check StorageClass binding mode**

```bash
kubectl describe storageclass gp2
```

Note the `VolumeBindingMode: WaitForFirstConsumer` - this means PV won't be created until a pod uses the PVC.

7. **Create deployment that uses the PVC**

```bash
cat <<EOF | tee ./nginx-deployment-with-pvc.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-volume-claim
          mountPath: /tmp/dare
      volumes:
      - name: nginx-volume-claim
        persistentVolumeClaim:
          claimName: nginx-volume-claim
EOF
```

8. **Apply the deployment**

```bash
kubectl apply -f nginx-deployment-with-pvc.yaml
```

9. **Verify PV was automatically created**

```bash
kubectl get pv
```

You'll see a PV automatically created with name like `pvc-89ba00d9-68f4-4039-b19e-a6471aad6a1e`

10. **Verify PVC is now bound**

```bash
kubectl get pvc
```

Status should now be `Bound`.

11. **Verify in AWS console**

Search the PV name in AWS EC2 console → Elastic Block Store → Volumes. You'll see the volume was created automatically.

---

## Task 5: Work with ConfigMaps for Configuration Persistence

### Objective
Use ConfigMaps to manage and persist configuration files.

### Steps

1. **Remove volume configurations to start fresh**

Edit the deployment to remove volumeMounts and PVC sections:
```bash
kubectl edit deployment nginx-deployment
```
Remove the `volumeMounts` and `volumes` sections entirely.

2. **Port forward and verify nginx works**

```bash
kubectl port-forward deployment/nginx-deployment 8080:80
```
Visit `http://localhost:8080` - you should see the "Welcome to nginx" page.

3. **Copy the default index.html content**

```bash
# Get pod name
kubectl get pods

# Exec into pod
kubectl exec -it nginx-deployment-79d8c764bc-j6sp9 -- bash

# View and copy the HTML content
cat /usr/share/nginx/html/index.html

# Copy the output to your local machine - save as index.html
exit
```

4. **Create a ConfigMap from the HTML file**

```bash
cat <<EOF | tee ./nginx-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: website-index-file
data:
  index-file: |
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
    html { color-scheme: light dark; }
    body { width: 35em; margin: 0 auto;
    font-family: Tahoma, Verdana, Arial, sans-serif; }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>

    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>

    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>
EOF
```

5. **Apply the ConfigMap**

```bash
kubectl apply -f nginx-configmap.yaml
```

6. **Verify ConfigMap creation**

```bash
kubectl get configmap
# or
kubectl get cm
```

7. **Update deployment to use the ConfigMap**

```bash
cat <<EOF | tee ./nginx-pod-with-cm.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
          - name: config
            mountPath: /usr/share/nginx/html
            readOnly: true
      volumes:
      - name: config
        configMap:
          name: website-index-file
          items:
          - key: index-file
            path: index.html
EOF
```

8. **Apply the updated deployment**

```bash
kubectl apply -f nginx-pod-with-cm.yaml
```

9. **Verify the ConfigMap is being used**

```bash
# Exec into the pod
kubectl exec -it <pod-name> -- bash

# Check the index.html file - it should be a symlink
ls -ltr /usr/share/nginx/html

# Expected output shows: index.html -> ..data/index.html
exit
```

10. **Edit the ConfigMap to change content**

```bash
kubectl edit cm website-index-file
```

Modify the HTML content - change "Welcome to nginx!" to something else, save and exit.

11. **Verify changes took effect**

Port forward again and refresh the browser:
```bash
kubectl port-forward deployment/nginx-deployment 8080:80
```

The page should update automatically without pod restart.

12. **Restart deployment (optional)**

```bash
kubectl rollout restart deploy nginx-deployment
```

---

## Important Concepts to Understand

### Volume vs PersistentVolume vs PersistentVolumeClaim

| Concept | Scope | Lifecycle | Purpose |
|---------|-------|-----------|---------|
| Volume | Pod | Same as pod | Basic storage attached to pod |
| PersistentVolume (PV) | Cluster | Independent of pods | Cluster storage resource |
| PersistentVolumeClaim (PVC) | Namespace | Independent of pods | Request for storage |

### Access Modes
- **ReadWriteOnce (RWO)**: Volume can be mounted as read-write by a single node
- **ReadOnlyMany (ROX)**: Volume can be mounted as read-only by many nodes
- **ReadWriteMany (RWX)**: Volume can be mounted as read-write by many nodes

### StorageClass Binding Modes
- **Immediate**: PV created immediately when PVC is created
- **WaitForFirstConsumer**: PV created only when a pod uses the PVC (default for gp2 in EKS)

### Reclaim Policies
- **Delete**: Delete PV and underlying storage when PVC is deleted
- **Retain**: Keep PV and storage for manual reclamation
- **Recycle**: Scrub volume and make available for new claim (deprecated)

---

## Verification Checklist

- [ ] Initial nginx deployment runs without volume
- [ ] Successfully exec'd into pod and viewed nginx configuration
- [ ] Created EBS volume in correct availability zone
- [ ] Updated deployment with volume spec
- [ ] Added volumeMounts to deployment
- [ ] Verified 403 error (expected - volume overwrote default files)
- [ ] Checked StorageClass exists in cluster
- [ ] Created and applied PVC manifest
- [ ] PVC shows Pending status before pod creation
- [ ] PVC shows Bound status after pod creation
- [ ] PV automatically created in AWS
- [ ] ConfigMap created from index.html
- [ ] Deployment updated to use ConfigMap
- [ ] ConfigMap changes reflect without pod restart
- [ ] Deployment successfully restarted

---

## Common Issues and Troubleshooting

### Issue: "volume node affinity conflict"
**Cause**: PV created in a different availability zone than the pod's node
**Solution**: Ensure volume is created in the same AZ as the node running your pod

### Issue: PVC stuck in Pending
**Cause**: No StorageClass or WaitForFirstConsumer binding mode
**Solution**: Create a pod that uses the PVC to trigger binding

### Issue: 403 Forbidden after mounting volume
**Cause**: Empty volume mounted over directory with existing files
**Solution**: Either pre-populate the volume with data or adjust mount path

### Issue: ConfigMap changes not showing
**Cause**: Pod may have cached the old config
**Solution**: Wait a few seconds (kubelet syncs periodically) or restart the pod

### Issue: Cannot delete PVC because it's in use
**Cause**: Storage Object in Use Protection
**Solution**: Delete the pod using the PVC first

---

## Cleanup Commands

```bash
# Delete deployment
kubectl delete deployment nginx-deployment

# Delete PVC (will also delete PV if reclaim policy is Delete)
kubectl delete pvc nginx-volume-claim

# Delete ConfigMap
kubectl delete cm website-index-file

# Delete manually created EBS volumes from AWS console or CLI
aws ec2 delete-volume --volume-id vol-xxxxxxxxxxxxxxxxx
```

---

## Key Takeaways

1. **Containers are stateless by design** - data doesn't persist across restarts
2. **Volumes provide storage but need proper mounting** - using volumeMounts
3. **Manual volume creation is error-prone** - requires matching AZs and updating volume IDs
4. **PVC with StorageClass enables dynamic provisioning** - volumes created automatically
5. **ConfigMaps are ideal for configuration files** - changes propagate without pod restarts
6. **PVs are cluster-wide** - PVCs are namespace-scoped
7. **WaitForFirstConsumer binding mode** - PV created only when needed, ensuring correct AZ placement