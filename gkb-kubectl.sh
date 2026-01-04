#!/bin/bash
# Quick kubectl access to GKB cluster
# Usage: ./gkb-kubectl.sh [kubectl commands]
# Examples:
#   ./gkb-kubectl.sh get nodes
#   ./gkb-kubectl.sh get pods -A
#   ./gkb-kubectl.sh describe node gkb

export KUBECONFIG=~/.kube/gkb-config

if [ $# -eq 0 ]; then
    echo "GKB Kubernetes Cluster Access"
    echo "=============================="
    echo ""
    echo "Usage: $0 <kubectl-command>"
    echo ""
    echo "Examples:"
    echo "  $0 get nodes"
    echo "  $0 get pods -A"
    echo "  $0 cluster-info"
    echo "  $0 top nodes"
    echo ""
    echo "Or set KUBECONFIG manually:"
    echo "  export KUBECONFIG=~/.kube/gkb-config"
    echo "  kubectl get nodes"
    exit 0
fi

kubectl "$@"
