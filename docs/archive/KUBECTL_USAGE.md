# kubectl Usage Guide for GKB Cluster

## Issue Resolved: Version Mismatch

**Problem:** kubectl v1.35.0 was incompatible with K3s v1.34.3+k3s1
**Solution:** Installed kubectl v1.34.3 to match the server version

---

## How to Use kubectl with GKB Cluster

### Method 1: Set KUBECONFIG Environment Variable (Recommended)

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
export KUBECONFIG=~/.kube/gkb-config
```

Then reload your shell:
```bash
source ~/.zshrc
```

Now you can use kubectl directly:
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

### Method 2: Use the Convenience Script

```bash
cd /Users/ganesh/projects/gk/k
./gkb-kubectl.sh get nodes
./gkb-kubectl.sh get pods -A
./gkb-kubectl.sh cluster-info
```

### Method 3: Create an Alias

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias kgkb='kubectl --kubeconfig=~/.kube/gkb-config'
```

Then use:
```bash
kgkb get nodes
kgkb get pods -A
```

### Method 4: Specify KUBECONFIG Each Time

```bash
export KUBECONFIG=~/.kube/gkb-config
kubectl get nodes
```

---

## Verify kubectl Version

Make sure you're using kubectl v1.34.x:

```bash
kubectl version --client
```

Should show: `Client Version: v1.34.3`

---

## Common Commands

```bash
# Cluster information
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# View all resources
kubectl get all -A

# View pods
kubectl get pods -A
kubectl get pods -n kube-system

# View services
kubectl get services -A

# View deployments
kubectl get deployments -A

# Describe resources
kubectl describe node gkb
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # Follow logs

# Resource usage
kubectl top nodes
kubectl top pods -A
```

---

## Test Your Connection

Run this to verify everything is working:

```bash
export KUBECONFIG=~/.kube/gkb-config
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

Expected output:
- Node `gkb` should show as `Ready`
- All system pods should show as `Running` or `Completed`
- Cluster info should show control plane running at `https://gkb:6443`

---

## Troubleshooting

### Error: "the server could not find the requested resource"
- **Cause:** Version mismatch between kubectl client and K3s server
- **Solution:** Use kubectl v1.34.x (already installed)
- **Verify:** `kubectl version`

### Error: "Unable to connect to the server"
- **Cause:** Network connectivity issue
- **Solution:**
  - Verify SSH access: `ssh ganesh@gkb`
  - Check if K3s is running: `ssh ganesh@gkb "systemctl status k3s"`
  - Verify the server URL in kubeconfig: `cat ~/.kube/gkb-config | grep server:`

### Error: "error loading config file"
- **Cause:** KUBECONFIG not set or file doesn't exist
- **Solution:** `export KUBECONFIG=~/.kube/gkb-config`

---

## kubectl Versions

**Current Setup:**
- Local kubectl: v1.34.3 (matches K3s server)
- K3s server: v1.34.3+k3s1

**Note:** The Kubernetes version skew policy requires kubectl to be within ±1 minor version of the API server. Always try to match versions exactly for best compatibility.

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Set kubeconfig | `export KUBECONFIG=~/.kube/gkb-config` |
| View nodes | `kubectl get nodes` |
| View all pods | `kubectl get pods -A` |
| View system pods | `kubectl get pods -n kube-system` |
| Cluster info | `kubectl cluster-info` |
| Resource usage | `kubectl top nodes` |
| Pod logs | `kubectl logs <pod-name>` |
| Describe node | `kubectl describe node gkb` |
| All resources | `kubectl get all -A` |

---

*Last Updated: 2026-01-04*
