#!/bin/bash
# Verify GPU support in Kubernetes cluster

set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "=========================================="
log "GPU Support Verification"
log "=========================================="

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    log "ERROR: Not connected to a cluster"
    exit 1
fi

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' 2>/dev/null || echo "unknown")
log "Cluster: $CLUSTER_NAME"

# Check if GKE
if kubectl get nodes -o json | jq -r '.items[0].metadata.labels."cloud.google.com/gke-nodepool"' &>/dev/null; then
    log "✓ Detected GKE cluster (built-in GPU support)"
    IS_GKE=true
else
    log "⚠ Non-GKE cluster (may need GPU Operator)"
    IS_GKE=false
fi

echo ""
log "Checking nodes for GPU support..."

# Check all nodes
GPU_NODES=0
NO_GPU_NODES=0

for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    GPU_COUNT=$(kubectl get node $node -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' 2>/dev/null || echo "")
    
    if [ -n "$GPU_COUNT" ] && [ "$GPU_COUNT" != "null" ]; then
        log "✓ $node: $GPU_COUNT GPU(s) available"
        GPU_NODES=$((GPU_NODES + 1))
    else
        log "✗ $node: No GPU support"
        NO_GPU_NODES=$((NO_GPU_NODES + 1))
    fi
done

echo ""
log "=========================================="
log "Summary"
log "=========================================="
log "GPU-enabled nodes: $GPU_NODES"
log "Nodes without GPU: $NO_GPU_NODES"

if [ $GPU_NODES -eq 0 ]; then
    log ""
    log "⚠ WARNING: No GPU nodes found!"
    if [ "$IS_GKE" = "false" ]; then
        log "For non-GKE clusters, install GPU Operator:"
        log "  ./gpu-operator-install.sh"
    else
        log "For GKE, ensure you created a GPU node pool:"
        log "  Check: gcloud container node-pools list --cluster <cluster-name>"
    fi
else
    log ""
    log "✓ GPU support verified!"
fi

# Check device plugin (if not GKE)
if [ "$IS_GKE" = "false" ]; then
    echo ""
    log "Checking GPU Operator/Device Plugin..."
    
    if kubectl get daemonset -n gpu-operator nvidia-device-plugin-daemonset &>/dev/null; then
        log "✓ GPU Operator device plugin found"
    elif kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset &>/dev/null; then
        log "✓ NVIDIA device plugin found (kube-system)"
    else
        log "⚠ NVIDIA device plugin not found"
        log "  Install GPU Operator: ./gpu-operator-install.sh"
    fi
fi

echo ""
log "=========================================="

