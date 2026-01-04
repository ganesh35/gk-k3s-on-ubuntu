# K3s Installation Guide for GKB Server

> **Note:** This is a detailed installation guide. For post-installation quick start, see [README.md](README.md).

## Server Specifications
- **Model:** Fujitsu Esprimo Q920 Mini PC
- **CPU:** Intel Core i5
- **RAM:** 8GB
- **Storage:** 240GB SSD
- **OS:** Ubuntu Server
- **Hostname:** gkb

## What is K3s?
K3s is a lightweight, certified Kubernetes distribution designed for edge computing, IoT, and resource-constrained environments. It's perfect for single-node deployments like the gkb server.

## Installation Overview

### Prerequisites
- Ubuntu Server (installed ✓)
- SSH access with sudo privileges (configured ✓)
- Minimum 1GB RAM available
- Port 6443 for Kubernetes API server
- Ports 10250-10255 for kubelet

### Installation Steps

#### 1. System Preparation
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y curl wget git

# Disable swap (Kubernetes requirement)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

#### 2. K3s Installation
```bash
# Install K3s (single-node server)
curl -sfL https://get.k3s.io | sh -

# K3s will:
# - Install kubectl, crictl, and other tools
# - Set up systemd service (k3s.service)
# - Configure kubeconfig at /etc/rancher/k3s/k3s.yaml
# - Start the cluster automatically
```

#### 3. Verify Installation
```bash
# Check K3s service status
sudo systemctl status k3s

# Check cluster nodes
sudo k3s kubectl get nodes

# Check all pods
sudo k3s kubectl get pods -A
```

#### 4. Configure kubectl Access
```bash
# Create kubeconfig directory for current user
mkdir -p ~/.kube

# Copy K3s kubeconfig
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# Test kubectl access
kubectl get nodes
```

#### 5. Install Management Tools

**k9s - Terminal UI for Kubernetes**
```bash
# Install k9s
curl -sS https://webinstall.dev/k9s | bash
source ~/.bashrc
```

**Helm - Kubernetes Package Manager**
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 6. Enable Metrics Server (for monitoring)
```bash
# Metrics server is included with K3s by default
# Verify it's running
kubectl get deployment metrics-server -n kube-system
```

#### 7. Install Kubernetes Dashboard (Optional)
```bash
# Deploy dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Get access token
kubectl -n kubernetes-dashboard create token admin-user
```

## Resource Management

### Expected Resource Usage
- **K3s Control Plane:** ~1-1.5GB RAM
- **Ubuntu System:** ~500MB RAM
- **Available for Workloads:** ~6GB RAM
- **Storage:** 240GB (shared with OS)

### Best Practices for 8GB RAM
1. Use resource limits and requests for all pods
2. Monitor resource usage regularly
3. Use horizontal pod autoscaling carefully
4. Consider lightweight alternatives for common services
5. Implement pod priority and preemption

## Accessing the Cluster

### From gkb Server
```bash
kubectl get nodes
kubectl get pods -A
k9s  # Interactive terminal UI
```

### From Remote Machine (Your Mac)
```bash
# Copy kubeconfig from gkb
scp ganesh@gkb:/etc/rancher/k3s/k3s.yaml ~/.kube/gkb-config

# Update server URL in the config
sed -i '' 's/127.0.0.1/gkb/g' ~/.kube/gkb-config

# Use the config
export KUBECONFIG=~/.kube/gkb-config
kubectl get nodes
```

## Common Commands

```bash
# View cluster info
kubectl cluster-info

# Get all resources
kubectl get all -A

# View node details
kubectl describe node gkb

# Check resource usage
kubectl top nodes
kubectl top pods -A

# View logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Deploy a test application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get service nginx
```

## Troubleshooting

### Check K3s Service
```bash
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

### Check Container Runtime
```bash
sudo k3s crictl ps
sudo k3s crictl images
```

### Restart K3s
```bash
sudo systemctl restart k3s
```

### Uninstall K3s (if needed)
```bash
/usr/local/bin/k3s-uninstall.sh
```

## Next Steps

1. **Deploy Your First Application**
   - Create deployments and services
   - Set up ingress for HTTP routing
   - Configure persistent storage

2. **Set Up Monitoring**
   - Install Prometheus and Grafana
   - Configure alerts
   - Set up log aggregation

3. **Implement GitOps**
   - Install ArgoCD or Flux
   - Automate deployments
   - Version control your configurations

4. **Secure Your Cluster**
   - Set up network policies
   - Configure RBAC
   - Enable pod security standards
   - Regular updates and patches

## Useful Resources

- [K3s Official Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K9s Documentation](https://k9scli.io/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Installation Date:** 2026-01-04
**Installed By:** Claude Code
**Server:** ganesh@gkb
