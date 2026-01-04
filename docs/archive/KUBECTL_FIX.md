# kubectl Connection Issue - Resolution

## Issue Description

**Error Message:**
```
E0104 18:34:41.093872   48223 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: the server could not find the requested resource"
Error from server (NotFound): the server could not find the requested resource
```

**Date:** 2026-01-04
**Status:** ✓ RESOLVED

---

## Root Cause Analysis

The issue had two components:

### 1. Corrupted/Incomplete Kubeconfig
The original kubeconfig file (`~/.kube/gkb-config`) was copied from the K3s server while the cluster was still initializing. This resulted in incomplete or corrupted certificate data that caused API communication failures.

### 2. Environment Variable Not Active
The `KUBECONFIG` environment variable was added to `~/.zshrc` but wasn't active in the current shell session until the shell configuration was reloaded.

---

## Resolution Steps

### Step 1: Verified Connectivity
```bash
# Hostname resolution
ping gkb
# Result: OK - resolves to 192.168.188.140

# Port connectivity
nc -zv gkb 6443
# Result: OK - Connection succeeded
```

### Step 2: Obtained Fresh Kubeconfig
```bash
# Copy fresh kubeconfig from server
scp ganesh@gkb:/etc/rancher/k3s/k3s.yaml ~/.kube/gkb-config-new

# Update server URL
sed -i '' 's/127.0.0.1/gkb/g' ~/.kube/gkb-config-new

# Test new config
KUBECONFIG=~/.kube/gkb-config-new kubectl get nodes
# Result: SUCCESS
```

### Step 3: Replaced Old Config
```bash
# Backup old config
mv ~/.kube/gkb-config ~/.kube/gkb-config.old

# Use new config
mv ~/.kube/gkb-config-new ~/.kube/gkb-config
```

### Step 4: Activated Environment Variable
```bash
# Reload shell configuration
source ~/.zshrc

# Verify KUBECONFIG is set
echo $KUBECONFIG
# Output: /Users/ganesh/.kube/gkb-config

# Test kubectl
kubectl get nodes
# Result: SUCCESS
```

---

## Verification Tests

All kubectl commands now work correctly:

```bash
✓ kubectl get nodes
✓ kubectl get pods -A
✓ kubectl get deployments
✓ kubectl get services
✓ kubectl cluster-info
✓ kubectl top nodes
```

### Test Results

**Cluster Info:**
```
Kubernetes control plane is running at https://gkb:6443
CoreDNS is running at https://gkb:6443
Metrics-server is running at https://gkb:6443
```

**Node Status:**
```
NAME   STATUS   ROLES           AGE   VERSION
gkb    Ready    control-plane   19m   v1.34.3+k3s1
```

**Resource Usage:**
```
NAME   CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
gkb    131m         3%       1001Mi          12%
```

---

## Current Configuration

### kubectl Version
- **Client:** v1.34.3 (matches K3s server)
- **Server:** v1.34.3+k3s1

### Kubeconfig Location
- **Path:** `~/.kube/gkb-config`
- **Environment Variable:** `KUBECONFIG=~/.kube/gkb-config` (in `~/.zshrc`)

### Server Details
- **API Server:** https://gkb:6443
- **Server IP:** 192.168.188.140
- **Authentication:** Client certificates

---

## Usage

### In Current Terminal
For the current terminal session, the environment variable is active after running:
```bash
source ~/.zshrc
```

Then use kubectl directly:
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

### In New Terminals
New terminal windows automatically load `~/.zshrc`, so the KUBECONFIG is already set:
```bash
# Just use kubectl directly
kubectl get nodes
```

### Alternative: Explicit KUBECONFIG
If needed, you can always explicitly set the kubeconfig:
```bash
KUBECONFIG=~/.kube/gkb-config kubectl get nodes
```

---

## Lessons Learned

1. **Timing Matters:** Always copy kubeconfig files after the cluster is fully initialized and ready.

2. **Verify Immediately:** Test kubectl access immediately after configuration to catch issues early.

3. **Environment Variables:** Remember that changes to shell profiles (`.zshrc`, `.bashrc`) only apply to:
   - New terminal sessions
   - Current sessions after running `source ~/.zshrc`

4. **Fresh Copies:** When troubleshooting kubeconfig issues, try getting a fresh copy from the server.

5. **Version Matching:** Ensure kubectl client version matches or is within ±1 minor version of the server.

---

## Troubleshooting Guide

### If you encounter similar issues in the future:

**Problem:** kubectl commands fail with API errors

**Steps:**
1. Verify server connectivity:
   ```bash
   ping gkb
   nc -zv gkb 6443
   ```

2. Check KUBECONFIG is set:
   ```bash
   echo $KUBECONFIG
   ```

3. If not set, reload shell:
   ```bash
   source ~/.zshrc
   ```

4. If still failing, get a fresh kubeconfig:
   ```bash
   scp ganesh@gkb:/etc/rancher/k3s/k3s.yaml ~/.kube/gkb-config
   sed -i '' 's/127.0.0.1/gkb/g' ~/.kube/gkb-config
   ```

5. Test with explicit KUBECONFIG:
   ```bash
   KUBECONFIG=~/.kube/gkb-config kubectl get nodes
   ```

---

## Files

- **Working kubeconfig:** `~/.kube/gkb-config`
- **Backup (corrupted):** `~/.kube/gkb-config.old`
- **Shell profile:** `~/.zshrc`

---

## Summary

✓ Issue identified: Corrupted kubeconfig + inactive environment variable
✓ Fresh kubeconfig obtained from K3s server
✓ Environment variable activated
✓ All kubectl commands verified working
✓ Remote cluster access fully functional

**Current Status:** kubectl is fully operational and configured for remote access to the gkb K3s cluster.

---

*Fixed: 2026-01-04*
*kubectl version: v1.34.3*
*K3s version: v1.34.3+k3s1*
