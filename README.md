# K3s Kubernetes Cluster - GKB Server

Production-ready K3s Kubernetes cluster running on Fujitsu Esprimo Q920 mini PC.

## Quick Info

| Property | Value |
|----------|-------|
| **Hostname** | gkb (192.168.188.140) |
| **Hardware** | Intel Core i5, 8GB RAM, 240GB SSD |
| **OS** | Ubuntu 24.04.1 LTS |
| **K3s Version** | v1.34.3+k3s1 |
| **Status** | ✓ Operational |

## Quick Start

### Access the Cluster

**From macOS (Remote):**
```bash
export KUBECONFIG=~/.kube/gkb-config
kubectl get nodes
```

**From GKB Server (SSH):**
```bash
ssh ganesh@gkb
kubectl get nodes
k9s  # Interactive UI
```

### Deploy a Test Application

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=NodePort

# Get access port
kubectl get service nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Access at: http://192.168.188.140:<NodePort>
```

### Common Commands

```bash
# Cluster status
kubectl get nodes
kubectl cluster-info
kubectl top nodes

# View workloads
kubectl get pods -A
kubectl get deployments -A
kubectl get services -A

# Monitor resources
kubectl top pods -A
```

## Documentation Structure

- **[K3S_INSTALLATION_GUIDE.md](K3S_INSTALLATION_GUIDE.md)** - Step-by-step installation instructions
- **[SETUP_COMPLETE.md](SETUP_COMPLETE.md)** - Comprehensive reference guide with all commands and usage
- **[TEST_APP_DEPLOYMENT.md](TEST_APP_DEPLOYMENT.md)** - Tutorial for deploying test applications
- **[CLAUDE.md](CLAUDE.md)** - Guide for AI assistants (Claude Code)

## What's Installed

### On GKB Server
- K3s Kubernetes (v1.34.3+k3s1)
- kubectl - Kubernetes CLI
- k9s (v0.50.16) - Terminal UI
- Helm (v3.19.4) - Package manager
- kubectx/kubens - Context switching tools

### On macOS
- kubectl (v1.34.3) - **Must match server version**
- Kubeconfig at `~/.kube/gkb-config`

### K3s Built-in Components
- **Traefik** - Ingress controller and load balancer
- **CoreDNS** - Internal DNS service
- **Metrics Server** - Resource metrics (`kubectl top`)
- **Local Path Provisioner** - Persistent storage

## Resource Capacity

| Component | Usage |
|-----------|-------|
| **Total RAM** | 8GB |
| **K3s Control Plane** | ~1.2GB |
| **System Overhead** | ~500MB |
| **Available for Workloads** | ~6GB |
| **Disk** | 240GB SSD (9% used) |

**Note:** Always set resource limits/requests in deployments to prevent resource exhaustion.

## Important Notes

### kubectl Version Matching
The kubectl client **must** match the K3s server version (v1.34.3). Version skew beyond ±1 minor version will cause API errors.

```bash
# Verify versions match
kubectl version
```

### Kubeconfig Setup

Add to `~/.zshrc` for persistent access:
```bash
export KUBECONFIG=~/.kube/gkb-config
```

Then reload: `source ~/.zshrc`

### Single-Node Limitations
- No high availability (single point of failure)
- All pod replicas run on same node
- Limited to 8GB total RAM

## Scripts

- **`install-k3s.sh`** - Automated K3s installation with validation
- **`gkb-kubectl.sh`** - Convenience wrapper for kubectl commands
- **`test-nginx-deployment.yaml`** - Example deployment manifest with resource limits

## Getting Started

### 1. Install K3s (if not already done)
See [K3S_INSTALLATION_GUIDE.md](K3S_INSTALLATION_GUIDE.md)

### 2. Configure Remote Access
```bash
# Copy kubeconfig from server
scp ganesh@gkb:/etc/rancher/k3s/k3s.yaml ~/.kube/gkb-config

# Update server URL
sed -i '' 's/127.0.0.1/gkb/g' ~/.kube/gkb-config

# Add to shell profile
echo 'export KUBECONFIG=~/.kube/gkb-config' >> ~/.zshrc
source ~/.zshrc
```

### 3. Deploy Your First App
```bash
kubectl apply -f test-nginx-deployment.yaml
kubectl get all
```

### 4. Access NodePort Services
NodePort range: 30000-32767

Access at: `http://192.168.188.140:<nodePort>`

## Troubleshooting

### "server could not find the requested resource"
- **Cause:** kubectl version mismatch or corrupted kubeconfig
- **Solution:** Ensure kubectl v1.34.3 and get fresh kubeconfig from server

### "Unable to connect to the server"
- **Cause:** Network issue or K3s not running
- **Solution:**
  ```bash
  ping gkb                                    # Test connectivity
  nc -zv gkb 6443                            # Test API port
  ssh ganesh@gkb "systemctl status k3s"      # Check service
  ```

### KUBECONFIG not set
```bash
echo $KUBECONFIG                  # Should show: /Users/ganesh/.kube/gkb-config
source ~/.zshrc                   # Reload if empty
```

## Next Steps

- **Monitor with Prometheus/Grafana** - Install monitoring stack
- **Set up GitOps** - Deploy ArgoCD or Flux for automated deployments
- **Configure Ingress** - Use Traefik for HTTP routing
- **Implement RBAC** - Set up proper access controls
- **Add Persistent Storage** - Use local-path storage class for stateful apps

## Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [k9s Documentation](https://k9scli.io/)
- [Helm Charts](https://artifacthub.io/)

---

**Installation Date:** 2026-01-04
**Maintained By:** ganesh@gkb
**Cluster Status:** ✓ Production Ready
