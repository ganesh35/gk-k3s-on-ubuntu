# K3s Installation Complete - GKB Server

> **Quick Start?** See [README.md](README.md) for quick access instructions and common commands.
>
> This document is a comprehensive reference guide with detailed explanations and examples.

## Installation Summary

**Date:** 2026-01-04
**Server:** ganesh@gkb (Fujitsu Esprimo Q920)
**K3s Version:** v1.34.3+k3s1
**Status:** ✓ OPERATIONAL

---

## What Was Installed

### On GKB Server
- **K3s Kubernetes** (lightweight distribution)
- **kubectl** - Kubernetes CLI
- **k9s** (v0.50.16) - Terminal UI for Kubernetes
- **Helm** (v3.19.4) - Kubernetes package manager
- **kubectx/kubens** - Context and namespace switching tools

### On Your Mac
- **kubectl** (v1.35.0) - Kubernetes CLI
- **Kubeconfig** for remote access at `~/.kube/gkb-config`

---

## Cluster Information

```
Node: gkb
Status: Ready
Role: control-plane
Internal IP: 192.168.188.140
OS: Ubuntu 24.04.1 LTS
Kernel: 6.8.0-90-generic
```

### System Pods Running
- CoreDNS (DNS service)
- Traefik (Ingress controller & load balancer)
- Metrics Server (resource metrics)
- Local Path Provisioner (persistent storage)

### Resource Usage
- **Total RAM:** 7.6GB
- **Used RAM:** ~1.2GB (K3s + system)
- **Available for Workloads:** ~6GB
- **Disk Usage:** 9% (7.7GB used / 98GB total)

---

## How to Access the Cluster

### From GKB Server (SSH)
```bash
ssh ganesh@gkb

# Using kubectl
kubectl get nodes
kubectl get pods -A
kubectl cluster-info

# Using k9s (interactive terminal UI)
k9s

# Using helm
helm list -A
```

### From Your Mac (Remote Access)

**Option 1: Using the convenience script**
```bash
cd /Users/ganesh/projects/gk/k
./gkb-kubectl.sh get nodes
./gkb-kubectl.sh get pods -A
./gkb-kubectl.sh top nodes
```

**Option 2: Set KUBECONFIG environment variable**
```bash
export KUBECONFIG=~/.kube/gkb-config
kubectl get nodes
kubectl get pods -A
```

**Option 3: Add to your shell profile** (for permanent access)
```bash
# Add to ~/.zshrc or ~/.bashrc
alias kgkb='kubectl --kubeconfig=~/.kube/gkb-config'

# Then use:
kgkb get nodes
kgkb get pods -A
```

---

## Quick Start Guide

### 1. Deploy Your First Application

```bash
# Deploy nginx
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=NodePort

# Check the deployment
kubectl get deployment nginx
kubectl get pods -l app=nginx
kubectl get service nginx

# Get the NodePort
kubectl get service nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Access it (from gkb or your network)
curl http://192.168.188.140:<NodePort>
```

### 2. View Logs
```bash
# Get pod name
kubectl get pods

# View logs
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>
```

### 3. Execute Commands in Pods
```bash
kubectl exec -it <pod-name> -- /bin/bash
```

### 4. Scale Applications
```bash
kubectl scale deployment nginx --replicas=3
kubectl get pods -w
```

### 5. Delete Resources
```bash
kubectl delete deployment nginx
kubectl delete service nginx
```

---

## Useful Commands

### Cluster Management
```bash
kubectl cluster-info                    # Cluster information
kubectl get nodes -o wide              # Node details
kubectl top nodes                      # Node resource usage
kubectl top pods -A                    # Pod resource usage
kubectl get all -A                     # All resources in all namespaces
```

### Pod Management
```bash
kubectl get pods -A                    # All pods
kubectl get pods -n kube-system       # Pods in specific namespace
kubectl describe pod <pod-name>       # Pod details
kubectl logs <pod-name>               # Pod logs
kubectl logs <pod-name> -f            # Follow logs
kubectl exec -it <pod-name> -- sh     # Shell into pod
```

### Service Management
```bash
kubectl get services -A                # All services
kubectl get endpoints                  # Service endpoints
kubectl describe service <svc-name>   # Service details
```

### Deployment Management
```bash
kubectl get deployments -A            # All deployments
kubectl describe deployment <name>    # Deployment details
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment <name>
kubectl rollout history deployment <name>
```

### Namespace Management
```bash
kubectl get namespaces                # List namespaces
kubectl create namespace <name>       # Create namespace
kubectl delete namespace <name>       # Delete namespace
kubens <name>                         # Switch namespace (if using kubens)
```

---

## Using Helm (Package Manager)

### Add Repositories
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

### Search and Install Charts
```bash
helm search repo nginx
helm install my-nginx bitnami/nginx
helm list
helm uninstall my-nginx
```

### Common Helm Charts
- **Monitoring:** prometheus, grafana
- **Databases:** postgresql, mysql, mongodb, redis
- **Web:** nginx, apache
- **CI/CD:** jenkins, gitlab

---

## Using k9s (Interactive UI)

```bash
# On gkb server via SSH
ssh ganesh@gkb
k9s
```

**k9s Keyboard Shortcuts:**
- `:pods` - View pods
- `:deploy` - View deployments
- `:svc` - View services
- `:nodes` - View nodes
- `/` - Filter resources
- `d` - Describe resource
- `l` - View logs
- `s` - Shell into pod
- `Ctrl+d` - Delete resource
- `:q` or `Ctrl+c` - Quit

---

## Next Steps

### 1. Set Up Monitoring
```bash
# Install metrics-server (already included with K3s)
kubectl top nodes
kubectl top pods -A

# For more advanced monitoring, install Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

### 2. Configure Persistent Storage
K3s includes local-path-provisioner by default:
```bash
kubectl get storageclass
# Use "local-path" as storageClassName in your PVCs
```

### 3. Set Up Ingress for HTTP Routing
Traefik is already installed as the default ingress controller:
```bash
kubectl get service traefik -n kube-system
```

### 4. Deploy a Sample Application
See the Quick Start Guide above for deploying nginx.

### 5. Implement Security Best Practices
- Set resource limits and requests
- Use network policies
- Configure RBAC
- Enable pod security standards
- Regular updates

---

## Troubleshooting

### Check K3s Service Status
```bash
ssh ganesh@gkb
systemctl status k3s
journalctl -u k3s -f
```

### Check Pod Issues
```bash
kubectl get pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Restart K3s
```bash
ssh ganesh@gkb
sudo systemctl restart k3s
```

### Check Node Resources
```bash
kubectl describe node gkb
kubectl top node gkb
```

### Network Issues
```bash
kubectl get endpoints
kubectl get service -A
kubectl describe service <svc-name>
```

---

## Files Created

### On Your Mac (`/Users/ganesh/projects/gk/k/`)
- `K3S_INSTALLATION_GUIDE.md` - Comprehensive installation guide
- `install-k3s.sh` - Installation script
- `gkb-kubectl.sh` - Convenience script for kubectl access
- `SETUP_COMPLETE.md` - This file
- `~/.kube/gkb-config` - Kubeconfig for remote access

### On GKB Server (`/home/ganesh/`)
- `install-k3s.sh` - Installation script
- `k3s-install-summary.txt` - Installation summary
- `~/.kube/config` - Kubeconfig

---

## Important Notes

1. **Resource Constraints:** With 8GB RAM, be mindful of resource usage. Always set resource limits and requests for your workloads.

2. **Single-Node Cluster:** This is a single-node cluster. High availability requires multiple nodes.

3. **Network Access:** The cluster is accessible at `192.168.188.140:6443`. Ensure this IP is accessible from your network.

4. **Security:** The current setup uses the default kubeconfig. For production, implement proper authentication and RBAC.

5. **Backups:** Consider backing up `/etc/rancher/k3s/` and your workload manifests regularly.

6. **Updates:** Keep K3s updated:
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```

---

## Support Resources

- **K3s Documentation:** https://docs.k3s.io/
- **Kubernetes Documentation:** https://kubernetes.io/docs/
- **k9s Documentation:** https://k9scli.io/
- **Helm Documentation:** https://helm.sh/docs/
- **Traefik Documentation:** https://doc.traefik.io/traefik/

---

## Summary

Your K3s Kubernetes cluster is now fully operational on the GKB server! You can:
- Access it from the server itself via SSH
- Manage it remotely from your Mac
- Deploy applications, services, and workloads
- Use interactive tools like k9s
- Install applications via Helm

**Cluster is ready for workloads!** 🎉

---

*Installation completed on: 2026-01-04*
*Managed by: Claude Code*
