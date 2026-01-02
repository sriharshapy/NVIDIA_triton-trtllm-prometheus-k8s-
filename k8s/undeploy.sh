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
kubectl delete -f "$SCRIPT_DIR/openwebui-service.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/prometheus-service.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting deployments..."
kubectl delete -f "$SCRIPT_DIR/deployment.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/openwebui-deployment.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/prometheus-deployment.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting PVCs..."
kubectl delete -f "$SCRIPT_DIR/pvc.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/openwebui-pvc.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/prometheus-pvc.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting ConfigMaps..."
kubectl delete -f "$SCRIPT_DIR/configmap.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/openwebui-configmap.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/prometheus-configmap.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting ResourceQuota and LimitRange..."
kubectl delete -f "$SCRIPT_DIR/resource-quota.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"
kubectl delete -f "$SCRIPT_DIR/limit-range.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Deleting namespace..."
kubectl delete -f "$SCRIPT_DIR/namespace.yaml" --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"

log "INFO" "=========================================="
log "INFO" "Undeployment completed!"
log "INFO" "=========================================="

