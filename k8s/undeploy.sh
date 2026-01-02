#!/bin/bash
# Undeploy script for Kubernetes resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="./logs/k8s_undeploy_$(date +%Y%m%d_%H%M%S).log"

mkdir -p ./logs

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log "INFO" "=========================================="
log "INFO" "Undeploying Kubernetes Resources"
log "INFO" "=========================================="

# Delete resources in reverse order
log "INFO" "Deleting services..."
kubectl delete -f "$SCRIPT_DIR/service.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting deployment..."
kubectl delete -f "$SCRIPT_DIR/deployment.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting PVC..."
kubectl delete -f "$SCRIPT_DIR/pvc.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting ConfigMap..."
kubectl delete -f "$SCRIPT_DIR/configmap.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting namespace..."
kubectl delete -f "$SCRIPT_DIR/namespace.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "=========================================="
log "INFO" "Undeployment completed!"
log "INFO" "=========================================="

