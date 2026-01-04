# Test Application Deployment - nginx

> **Tutorial:** This is a detailed deployment tutorial. For quick deployment commands, see [README.md](README.md).

## Deployment Summary

**Status:** ✓ Successfully Deployed
**Application:** nginx web server
**Date:** 2026-01-04

---

## What Was Deployed

### Deployment Details
- **Name:** test-nginx
- **Image:** nginx:latest
- **Replicas:** 1
- **Pod Status:** Running
- **Container:** nginx on port 80

### Service Details
- **Name:** test-nginx-service
- **Type:** NodePort
- **Cluster IP:** 10.43.69.22
- **Port Mapping:** 80 (internal) → 32043 (external)

---

## Access Information

### From Within the Cluster
```bash
# Using cluster IP
curl http://10.43.69.22:80

# Using service name (DNS)
curl http://test-nginx-service:80
```

### From GKB Server
```bash
ssh ganesh@gkb
curl http://localhost:32043
curl http://192.168.188.140:32043
```

### From Your Network
Open a browser and navigate to:
```
http://192.168.188.140:32043
```

Or use curl:
```bash
curl http://192.168.188.140:32043
```

---

## Deployment Commands Used

```bash
# Create deployment
kubectl create deployment test-nginx --image=nginx:latest

# Expose as NodePort service
kubectl expose deployment test-nginx --port=80 --type=NodePort --name=test-nginx-service

# Check status
kubectl get deployment test-nginx
kubectl get pods -l app=test-nginx
kubectl get service test-nginx-service
```

---

## Managing the Application

### View Resources
```bash
ssh ganesh@gkb

# View deployment
kubectl get deployment test-nginx
kubectl describe deployment test-nginx

# View pods
kubectl get pods -l app=test-nginx
kubectl describe pod <pod-name>

# View service
kubectl get service test-nginx-service
kubectl describe service test-nginx-service

# View logs
kubectl logs -l app=test-nginx
kubectl logs -f <pod-name>  # Follow logs
```

### Scale the Application
```bash
# Scale to 3 replicas
kubectl scale deployment test-nginx --replicas=3

# Verify
kubectl get pods -l app=test-nginx -w
```

### Update the Application
```bash
# Update image
kubectl set image deployment/test-nginx nginx=nginx:1.25

# Check rollout status
kubectl rollout status deployment/test-nginx

# View rollout history
kubectl rollout history deployment/test-nginx

# Rollback if needed
kubectl rollout undo deployment/test-nginx
```

### Delete the Application
```bash
# Delete service
kubectl delete service test-nginx-service

# Delete deployment (also deletes pods)
kubectl delete deployment test-nginx

# Or delete both at once
kubectl delete deployment,service test-nginx test-nginx-service
```

---

## Using YAML Manifests

Instead of imperative commands, you can use declarative YAML files:

### Deployment YAML (`test-nginx-deployment.yaml`)
See the file: `/Users/ganesh/projects/gk/k/test-nginx-deployment.yaml`

### Apply the manifest
```bash
# Create/update resources
kubectl apply -f test-nginx-deployment.yaml

# Delete resources
kubectl delete -f test-nginx-deployment.yaml
```

---

## Verification Commands

```bash
# Check all resources
kubectl get all -l app=test-nginx

# Check deployment status
kubectl rollout status deployment/test-nginx

# Check service endpoints
kubectl get endpoints test-nginx-service

# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- http://test-nginx-service

# Check resource usage
kubectl top pod -l app=test-nginx
```

---

## Troubleshooting

### Pod Not Starting
```bash
# Check pod status
kubectl get pods -l app=test-nginx

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Service Not Accessible
```bash
# Check service
kubectl get service test-nginx-service
kubectl get endpoints test-nginx-service

# Verify pod labels match service selector
kubectl get pods -l app=test-nginx --show-labels

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- http://test-nginx-service
```

### Check Node Port
```bash
# Get the NodePort
kubectl get service test-nginx-service -o jsonpath='{.spec.ports[0].nodePort}'

# Check if port is listening on node
ssh ganesh@gkb "sudo netstat -tuln | grep 32043"
```

---

## Resource Usage

```bash
# View pod resource usage
kubectl top pod -l app=test-nginx

# View node resource usage
kubectl top nodes

# Check resource limits
kubectl describe deployment test-nginx | grep -A 5 Limits
```

---

## Next Steps

### 1. Deploy More Complex Applications
- Multi-container pods
- StatefulSets for databases
- ConfigMaps and Secrets for configuration
- Persistent Volumes for data storage

### 2. Set Up Ingress
Instead of NodePort, use Traefik Ingress for HTTP routing:

```bash
# Create Ingress resource
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-nginx-ingress
spec:
  rules:
  - host: nginx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-nginx-service
            port:
              number: 80
EOF

# Access via: http://nginx.local (add to /etc/hosts)
```

### 3. Add Health Checks
```yaml
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

### 4. Implement Monitoring
- Deploy Prometheus for metrics
- Set up Grafana dashboards
- Configure alerts

---

## Clean Up

To remove the test application:

```bash
ssh ganesh@gkb

# Delete all resources
kubectl delete deployment test-nginx
kubectl delete service test-nginx-service

# Or using labels
kubectl delete all -l app=test-nginx

# Verify deletion
kubectl get all -l app=test-nginx
```

---

## Important Notes

1. **NodePort Range:** K3s uses ports 30000-32767 for NodePort services by default.

2. **Resource Limits:** Always set resource limits and requests in production to prevent resource exhaustion.

3. **Security:** For production:
   - Use specific image tags instead of `latest`
   - Implement network policies
   - Use RBAC for access control
   - Run containers as non-root users

4. **High Availability:** Single replica means no redundancy. Use multiple replicas for production workloads.

5. **Persistent Data:** nginx container is stateless. For applications that need persistent storage, use PersistentVolumeClaims.

---

## Summary

✓ Test nginx application successfully deployed
✓ Accessible via NodePort 32043
✓ Running on gkb cluster (192.168.188.140:32043)
✓ Pod is healthy and serving requests

Your K3s cluster is fully functional and ready for production workloads!

---

*Deployed: 2026-01-04*
*Service: http://192.168.188.140:32043*
