#!/bin/bash

###############################################################################
# K3s Installation Script for GKB Server
# Description: Automated installation of K3s with management tools
# Date: 2026-01-04
# Server: gkb (Fujitsu Esprimo Q920 - i5, 8GB RAM, 240GB SSD)
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. It will use sudo when needed."
    exit 1
fi

print_header "K3s Installation Script - GKB Server"

log_info "Installation started at $(date)"
log_info "User: $(whoami)"
log_info "Hostname: $(hostname)"

###############################################################################
# 1. PREREQUISITES CHECK
###############################################################################

print_header "Step 1: Checking Prerequisites"

# Check if running on Linux
if [ "$(uname -s)" != "Linux" ]; then
    log_error "This script must be run on Linux"
    exit 1
fi
log_success "Running on Linux"

# Check available memory
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
log_info "Total memory: ${TOTAL_MEM}GB"
if [ "$TOTAL_MEM" -lt 4 ]; then
    log_warning "System has less than 4GB RAM. K3s may not perform optimally."
fi

# Check available disk space
AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
log_info "Available disk space: ${AVAILABLE_SPACE}GB"
if [ "$AVAILABLE_SPACE" -lt 10 ]; then
    log_warning "Less than 10GB disk space available"
fi

# Check if K3s is already installed
if command -v k3s &> /dev/null; then
    log_warning "K3s is already installed"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    log_info "Uninstalling existing K3s..."
    sudo /usr/local/bin/k3s-uninstall.sh || true
fi

###############################################################################
# 2. SYSTEM PREPARATION
###############################################################################

print_header "Step 2: Preparing System"

# Update package lists
log_info "Updating package lists..."
sudo apt update -qq

# Install required packages
log_info "Installing required packages..."
sudo apt install -y curl wget git vim nano htop net-tools > /dev/null 2>&1
log_success "Required packages installed"

# Disable swap (Kubernetes requirement)
log_info "Disabling swap..."
if swapon --show | grep -q '/'; then
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    log_success "Swap disabled"
else
    log_info "Swap is already disabled"
fi

# Enable IP forwarding
log_info "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p > /dev/null 2>&1
log_success "IP forwarding enabled"

###############################################################################
# 3. K3S INSTALLATION
###############################################################################

print_header "Step 3: Installing K3s"

log_info "Downloading and installing K3s..."
log_info "This may take a few minutes..."

# Install K3s
curl -sfL https://get.k3s.io | sh -

log_success "K3s installed successfully"

# Wait for K3s to be ready
log_info "Waiting for K3s to start..."
sleep 10

# Check K3s service status
if sudo systemctl is-active --quiet k3s; then
    log_success "K3s service is running"
else
    log_error "K3s service failed to start"
    sudo systemctl status k3s
    exit 1
fi

###############################################################################
# 4. CONFIGURE KUBECTL ACCESS
###############################################################################

print_header "Step 4: Configuring kubectl Access"

# Create .kube directory
mkdir -p ~/.kube

# Copy kubeconfig
log_info "Setting up kubeconfig..."
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
log_success "Kubeconfig configured at ~/.kube/config"

# Add kubectl alias to bashrc if not exists
if ! grep -q "alias k=" ~/.bashrc; then
    echo "alias k='kubectl'" >> ~/.bashrc
    log_success "Added kubectl alias 'k' to ~/.bashrc"
fi

# Wait for node to be ready
log_info "Waiting for cluster to be ready..."
COUNTER=0
MAX_WAIT=60
while [ $COUNTER -lt $MAX_WAIT ]; do
    if kubectl get nodes 2>/dev/null | grep -q " Ready "; then
        log_success "Cluster is ready"
        break
    fi
    sleep 2
    COUNTER=$((COUNTER+2))
    if [ $COUNTER -eq $MAX_WAIT ]; then
        log_error "Cluster did not become ready in time"
        exit 1
    fi
done

###############################################################################
# 5. INSTALL MANAGEMENT TOOLS
###############################################################################

print_header "Step 5: Installing Management Tools"

# Install k9s
log_info "Installing k9s (Kubernetes Terminal UI)..."
if command -v k9s &> /dev/null; then
    log_info "k9s is already installed"
else
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
    wget -q https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz
    tar -xzf k9s_Linux_amd64.tar.gz
    sudo mv k9s /usr/local/bin/
    rm k9s_Linux_amd64.tar.gz README.md LICENSE
    log_success "k9s installed successfully"
fi

# Install Helm
log_info "Installing Helm (Kubernetes Package Manager)..."
if command -v helm &> /dev/null; then
    log_info "Helm is already installed"
else
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > /dev/null 2>&1
    log_success "Helm installed successfully"
fi

# Install kubectx and kubens (optional but useful)
log_info "Installing kubectx and kubens..."
if ! command -v kubectx &> /dev/null; then
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx > /dev/null 2>&1
    sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
    log_success "kubectx and kubens installed"
else
    log_info "kubectx and kubens already installed"
fi

###############################################################################
# 6. VALIDATION
###############################################################################

print_header "Step 6: Validating Installation"

# Check cluster info
log_info "Cluster information:"
kubectl cluster-info

echo ""
log_info "Nodes status:"
kubectl get nodes -o wide

echo ""
log_info "System pods status:"
kubectl get pods -A

echo ""
log_info "K3s version:"
k3s --version

echo ""
log_info "kubectl version:"
kubectl version --short 2>/dev/null || kubectl version

###############################################################################
# 7. INSTALLATION SUMMARY
###############################################################################

print_header "Installation Summary"

echo ""
log_success "K3s installation completed successfully!"
echo ""
echo "Installation Details:"
echo "  - K3s installed and running"
echo "  - kubectl configured for current user"
echo "  - Management tools installed: k9s, helm, kubectx, kubens"
echo "  - Kubeconfig location: ~/.kube/config"
echo ""
echo "Quick Start Commands:"
echo "  kubectl get nodes                 # View cluster nodes"
echo "  kubectl get pods -A               # View all pods"
echo "  k9s                               # Launch K9s terminal UI"
echo "  helm list -A                      # List Helm releases"
echo ""
echo "System Resource Usage:"
free -h | grep Mem
echo ""

# Save installation info
INSTALL_INFO_FILE=~/k3s-install-info.txt
cat > $INSTALL_INFO_FILE <<EOF
K3s Installation Information
============================
Installation Date: $(date)
Hostname: $(hostname)
User: $(whoami)
K3s Version: $(k3s --version | head -n1)
Kubectl Version: $(kubectl version --short 2>/dev/null | head -n1)

Kubeconfig: ~/.kube/config

Management Tools:
- kubectl: $(which kubectl)
- k9s: $(which k9s)
- helm: $(which helm)
- kubectx: $(which kubectx)
- kubens: $(which kubens)

Cluster Info:
$(kubectl cluster-info)

Nodes:
$(kubectl get nodes)

System Pods:
$(kubectl get pods -n kube-system)
EOF

log_success "Installation info saved to: $INSTALL_INFO_FILE"

echo ""
log_info "To start using kubectl, run:"
echo "  source ~/.bashrc"
echo ""
log_info "To access the cluster from a remote machine:"
echo "  scp ganesh@gkb:/etc/rancher/k3s/k3s.yaml ~/.kube/gkb-config"
echo "  # Then update the server URL in the config file"
echo ""
log_info "To launch the Kubernetes Dashboard (optional):"
echo "  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
echo ""
log_success "Installation completed at $(date)"
echo ""
