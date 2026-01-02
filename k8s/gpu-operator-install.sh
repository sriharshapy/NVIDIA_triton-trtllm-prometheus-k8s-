#!/bin/bash
# Install NVIDIA GPU Operator for non-GKE Kubernetes clusters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="./logs/gpu_operator_install_$(date +%Y%m%d_%H%M%S).log"

mkdir -p ./logs

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log "INFO" "=========================================="
log "INFO" "NVIDIA GPU Operator Installation"
log "INFO" "=========================================="

# Check if running on GKE
if kubectl get nodes -o json | jq -r '.items[0].metadata.labels."cloud.google.com/gke-nodepool"' &>/dev/null; then
    log "WARNING" "Detected GKE cluster. GPU Operator is NOT needed!"
    log "INFO" "GKE has built-in GPU support. Skipping installation."
    log "INFO" "If you still want to install, set FORCE_INSTALL=true"
    
    if [ "${FORCE_INSTALL:-false}" != "true" ]; then
        exit 0
    fi
fi

# Check prerequisites
log "INFO" "Checking prerequisites..."

if ! command -v helm &> /dev/null; then
    log "ERROR" "Helm not found. Please install Helm 3.x"
    log "INFO" "Install from: https://helm.sh/docs/intro/install/"
    exit 1
fi

HELM_VERSION=$(helm version --short)
log "INFO" "✓ Helm found: $HELM_VERSION"

if ! kubectl cluster-info &> /dev/null; then
    log "ERROR" "kubectl is not connected to a cluster."
    exit 1
fi

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' 2>/dev/null || echo "unknown")
log "INFO" "✓ Connected to cluster: $CLUSTER_NAME"

# Check for existing GPU Operator
if kubectl get namespace gpu-operator &>/dev/null; then
    log "WARNING" "GPU Operator namespace already exists."
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Installation cancelled."
        exit 0
    fi
    log "INFO" "Uninstalling existing GPU Operator..."
    helm uninstall -n gpu-operator $(helm list -n gpu-operator -q) 2>&1 | tee -a "$LOG_FILE" || true
    kubectl delete namespace gpu-operator --wait=true --timeout=300s 2>&1 | tee -a "$LOG_FILE" || true
fi

# Add NVIDIA Helm repository
log "INFO" "Step 1: Adding NVIDIA Helm repository..."
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia 2>&1 | tee -a "$LOG_FILE"
helm repo update 2>&1 | tee -a "$LOG_FILE"
log "INFO" "✓ Helm repository added"

# Install GPU Operator
log "INFO" "Step 2: Installing GPU Operator..."
log "INFO" "This may take 5-10 minutes..."

helm install gpu-operator \
    -n gpu-operator --create-namespace \
    --wait --timeout 10m \
    nvidia/gpu-operator \
    2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "INFO" "✓ GPU Operator installed successfully"
else
    log "ERROR" "GPU Operator installation failed"
    exit 1
fi

# Wait for pods to be ready
log "INFO" "Step 3: Waiting for GPU Operator pods to be ready..."
sleep 30

timeout=600
elapsed=0
while [ $elapsed -lt $timeout ]; do
    READY=$(kubectl get pods -n gpu-operator --no-headers 2>/dev/null | grep -v Running | wc -l || echo "1")
    if [ "$READY" -eq 0 ]; then
        log "INFO" "✓ All GPU Operator pods are running"
        break
    fi
    sleep 10
    elapsed=$((elapsed + 10))
    log "INFO" "Waiting for pods... (${elapsed}s/${timeout}s)"
done

# Verify GPU support
log "INFO" "Step 4: Verifying GPU support..."

sleep 10  # Give device plugin time to register

GPU_NODES=$(kubectl get nodes -o json | jq -r '.items[] | select(.status.allocatable."nvidia.com/gpu" != null) | .metadata.name' 2>/dev/null || echo "")

if [ -n "$GPU_NODES" ]; then
    log "INFO" "✓ GPU support verified!"
    log "INFO" "GPU nodes found:"
    echo "$GPU_NODES" | while read node; do
        GPU_COUNT=$(kubectl get node $node -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' 2>/dev/null || echo "0")
        log "INFO" "  - $node: $GPU_COUNT GPU(s)"
    done
else
    log "WARNING" "No GPU nodes detected yet."
    log "INFO" "This may be normal if:"
    log "INFO" "  1. Nodes don't have GPUs"
    log "INFO" "  2. Device plugin is still initializing"
    log "INFO" "Check with: kubectl describe node <node-name> | grep nvidia.com/gpu"
fi

# Show pod status
log "INFO" "GPU Operator pod status:"
kubectl get pods -n gpu-operator 2>&1 | tee -a "$LOG_FILE"

log "INFO" "=========================================="
log "INFO" "GPU Operator installation completed!"
log "INFO" "=========================================="
log "INFO" "To verify GPU availability:"
log "INFO" "  kubectl describe node <node-name> | grep nvidia.com/gpu"
log "INFO" "  kubectl get pods -n gpu-operator"
log "INFO" "=========================================="

