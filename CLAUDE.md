# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains setup scripts and documentation for managing a K3s Kubernetes cluster running on a Fujitsu Esprimo Q920 mini PC (hostname: `gkb`) with Ubuntu Server.

**For quick reference, see [README.md](README.md) - the main documentation entry point.**

**Server Specifications:**
- **Hostname:** gkb (192.168.188.140)
- **Hardware:** Intel Core i5, 8GB RAM, 240GB SSD
- **OS:** Ubuntu 24.04.1 LTS (kernel 6.8.0-90-generic)
- **K3s Version:** v1.34.3+k3s1
- **kubectl Version:** v1.34.3 (client and server must match)

## Documentation Structure

- **README.md** - Main entry point with quick start, status overview, and common commands
- **K3S_INSTALLATION_GUIDE.md** - Step-by-step installation instructions for new setups
- **SETUP_COMPLETE.md** - Comprehensive reference guide with detailed explanations
- **TEST_APP_DEPLOYMENT.md** - Tutorial for deploying and managing test applications
- **CLAUDE.md** - This file - guidance for AI assistants
- **docs/archive/** - Historical troubleshooting documentation

## Cluster Access Methods

### From macOS (Remote Access)

The kubeconfig is located at `~/.kube/gkb-config` and should be set via environment variable:

```bash
export KUBECONFIG=~/.kube/gkb-config
kubectl get nodes
```

This environment variable should be added to `~/.zshrc` for persistence.

**Alternative: Using the convenience script:**
```bash
./gkb-kubectl.sh get nodes
./gkb-kubectl.sh get pods -A
```

### From GKB Server (SSH)

```bash
ssh ganesh@gkb
kubectl get nodes
k9s  # Interactive terminal UI
```

## Common Commands

### Cluster Management
```bash
kubectl get nodes -o wide              # Node details with IP addresses
kubectl top nodes                      # Resource usage (requires metrics-server)
kubectl cluster-info                   # Cluster endpoint information
```

### Deploy Applications
```bash
# Imperative approach
kubectl create deployment <name> --image=<image>
kubectl expose deployment <name> --port=<port> --type=NodePort

# Declarative approach (preferred)
kubectl apply -f <manifest.yaml>
kubectl delete -f <manifest.yaml>
```

### Access NodePort Services
After creating a NodePort service, access it at:
- From GKB server: `http://localhost:<nodePort>`
- From network: `http://192.168.188.140:<nodePort>`
- NodePort range: 30000-32767

### Monitoring
```bash
kubectl top nodes                      # Node resource usage
kubectl top pods -A                    # Pod resource usage across all namespaces
kubectl get pods -A -w                 # Watch all pods
kubectl logs -f <pod-name>             # Follow pod logs
```

## Architecture Notes

### K3s Components (Auto-installed)
- **Traefik:** Default ingress controller and load balancer (runs in kube-system namespace)
- **CoreDNS:** Internal DNS service for service discovery
- **Metrics Server:** Provides resource usage metrics for `kubectl top` commands
- **Local Path Provisioner:** Default storage class for persistent volumes

### Resource Constraints
With 8GB total RAM:
- K3s control plane: ~1-1.5GB
- System overhead: ~500MB
- **Available for workloads:** ~6GB

**Important:** Always set resource limits and requests in pod specifications to prevent resource exhaustion. See `test-nginx-deployment.yaml` for an example.

### Single-Node Cluster Limitations
- No high availability (single point of failure)
- Pod replicas run on the same physical node
- Limited compute resources compared to multi-node clusters

## Key Files

- **`install-k3s.sh`:** Automated K3s installation script with validation checks
- **`gkb-kubectl.sh`:** Convenience wrapper for kubectl with correct KUBECONFIG
- **`test-nginx-deployment.yaml`:** Example deployment manifest with resource limits
- **`~/.kube/gkb-config`:** Kubeconfig file for remote cluster access

## Installation/Setup

To set up K3s on a fresh Ubuntu server, run `install-k3s.sh` on the target server:

```bash
scp install-k3s.sh ganesh@<server>:~/
ssh ganesh@<server>
chmod +x install-k3s.sh
./install-k3s.sh
```

The script will:
1. Verify prerequisites (RAM, disk space, OS)
2. Install K3s via the official installer
3. Configure kubectl access
4. Install management tools (k9s, helm, kubectx, kubens)
5. Validate the installation

After installation, copy the kubeconfig to your local machine:

```bash
scp ganesh@gkb:/etc/rancher/k3s/k3s.yaml ~/.kube/gkb-config
sed -i '' 's/127.0.0.1/gkb/g' ~/.kube/gkb-config
```

## Important kubectl Considerations

### Version Matching
The kubectl client version must match the K3s server version (±1 minor version tolerance). Current required version: v1.34.3.

Verify with:
```bash
kubectl version
```

### Kubeconfig Troubleshooting
If kubectl commands fail with API errors:

1. Verify connectivity: `ping gkb` and `nc -zv gkb 6443`
2. Check KUBECONFIG is set: `echo $KUBECONFIG`
3. If not set, reload shell: `source ~/.zshrc`
4. If still failing, obtain fresh kubeconfig from server
5. **Critical:** Always copy kubeconfig after the cluster is fully initialized

### Common Issues
- **"server could not find the requested resource":** Version mismatch or corrupted kubeconfig
- **"Unable to connect to the server":** Network issue or K3s service not running
- **Solution:** Get fresh kubeconfig from `/etc/rancher/k3s/k3s.yaml` on gkb server

## Management Tools Available

- **k9s:** Terminal-based Kubernetes UI (run via SSH on gkb server)
- **Helm:** Kubernetes package manager (v3.19.4)
- **kubectx/kubens:** Context and namespace switching utilities
- **kubectl:** Primary CLI tool (v1.34.3)

## Best Practices for This Cluster

1. **Resource Management:** Always specify resource requests and limits (memory/CPU)
2. **Image Tags:** Use specific version tags, avoid `:latest` in production
3. **Manifests:** Prefer declarative YAML over imperative commands for reproducibility
4. **Health Checks:** Add liveness and readiness probes to deployments
5. **Backups:** Regularly backup `/etc/rancher/k3s/` on the server
6. **Updates:** Keep K3s updated via: `curl -sfL https://get.k3s.io | sh -`
