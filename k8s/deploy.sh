#!/bin/bash
# Kubernetes deployment script for Qwen 3 8B with Triton

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/k8s_deploy_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log "INFO" "=========================================="
log "INFO" "Kubernetes Deployment Script"
log "INFO" "=========================================="

# Check prerequisites
log "INFO" "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    log "ERROR" "kubectl not found. Please install kubectl."
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    log "ERROR" "gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

# Check kubectl connection
if ! kubectl cluster-info &> /dev/null; then
    log "ERROR" "kubectl is not connected to a cluster."
    log "INFO" "Run: gcloud container clusters get-credentials <cluster-name> --zone <zone>"
    exit 1
fi

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' 2>/dev/null || echo "unknown")
log "INFO" "✓ Connected to cluster: $CLUSTER_NAME"

# Step 1: Create namespace
log "INFO" "Step 1: Creating namespace..."
kubectl apply -f "$SCRIPT_DIR/namespace.yaml" 2>&1 | tee -a "$LOG_FILE"
log "INFO" "✓ Namespace created"

# Step 2: Create ConfigMap
log "INFO" "Step 2: Creating ConfigMap..."
kubectl apply -f "$SCRIPT_DIR/configmap.yaml" 2>&1 | tee -a "$LOG_FILE"
log "INFO" "✓ ConfigMap created"

# Step 3: Create PVC
log "INFO" "Step 3: Creating PersistentVolumeClaim..."
kubectl apply -f "$SCRIPT_DIR/pvc.yaml" 2>&1 | tee -a "$LOG_FILE"

# Wait for PVC to be bound
log "INFO" "Waiting for PVC to be bound..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if kubectl get pvc model-storage -n triton-inference -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Bound; then
        log "INFO" "✓ PVC is bound"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    log "INFO" "Waiting for PVC... (${elapsed}s/${timeout}s)"
done

if [ $elapsed -ge $timeout ]; then
    log "WARNING" "PVC did not bind within timeout. Continuing anyway..."
fi

# Step 4: Upload model files to PVC
log "INFO" "Step 4: Preparing to upload model files..."
log "INFO" "Note: You need to upload model files to the PVC manually or use a job."
log "INFO" "Creating a temporary pod to upload files..."

# Create a job to copy model files (if MODEL_PATH is set)
if [ -n "${MODEL_PATH:-}" ] && [ -d "$MODEL_PATH" ]; then
    log "INFO" "Model path provided: $MODEL_PATH"
    log "INFO" "Creating upload job..."
    
    cat > /tmp/upload-job.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: model-upload
  namespace: triton-inference
spec:
  template:
    spec:
      containers:
      - name: upload
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Upload job - mount your model files here"
          echo "Or use: kubectl cp <local-path> triton-inference/<pod-name>:/models/"
          sleep 3600
        volumeMounts:
        - name: model-storage
          mountPath: /models
      volumes:
      - name: model-storage
        persistentVolumeClaim:
          claimName: model-storage
      restartPolicy: Never
EOF
    
    kubectl apply -f /tmp/upload-job.yaml 2>&1 | tee -a "$LOG_FILE"
    log "INFO" "Upload job created. Use 'kubectl cp' to copy files to the pod."
    log "INFO" "Example: kubectl cp <local-model-path> triton-inference/<pod-name>:/models/"
else
    log "WARNING" "MODEL_PATH not set. Skipping model upload."
    log "INFO" "To upload models later, use: kubectl cp <path> triton-inference/<pod>:/models/"
fi

# Step 5: Deploy Triton
log "INFO" "Step 5: Deploying Triton Inference Server..."
kubectl apply -f "$SCRIPT_DIR/deployment.yaml" 2>&1 | tee -a "$LOG_FILE"
log "INFO" "✓ Deployment created"

# Step 6: Create Services
log "INFO" "Step 6: Creating Services..."
kubectl apply -f "$SCRIPT_DIR/service.yaml" 2>&1 | tee -a "$LOG_FILE"
log "INFO" "✓ Services created"

# Step 7: Wait for deployment
log "INFO" "Step 7: Waiting for deployment to be ready..."
kubectl wait --for=condition=available \
    --timeout=600s \
    deployment/triton-qwen3-8b \
    -n triton-inference \
    2>&1 | tee -a "$LOG_FILE" || log "WARNING" "Deployment not ready within timeout"

# Step 8: Get service endpoints
log "INFO" "Step 8: Getting service endpoints..."
sleep 10

EXTERNAL_IP=$(kubectl get service triton-qwen3-8b -n triton-inference -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
    log "INFO" "✓ External IP allocated: $EXTERNAL_IP"
else
    log "INFO" "External IP is pending. It may take a few minutes to allocate."
    log "INFO" "Check with: kubectl get svc triton-qwen3-8b -n triton-inference"
fi

# Get pod status
log "INFO" "Pod status:"
kubectl get pods -n triton-inference -l app=qwen3-8b 2>&1 | tee -a "$LOG_FILE"

log "INFO" "=========================================="
log "INFO" "Deployment completed!"
log "INFO" "=========================================="
log "INFO" "Service endpoints:"
log "INFO" "  HTTP: http://${EXTERNAL_IP:-<pending>}:8000"
log "INFO" "  gRPC: ${EXTERNAL_IP:-<pending>}:8001"
log "INFO" "  Metrics: http://${EXTERNAL_IP:-<pending>}:8002/metrics"
log "INFO" ""
log "INFO" "To check status:"
log "INFO" "  kubectl get pods -n triton-inference"
log "INFO" "  kubectl logs -n triton-inference -l app=qwen3-8b"
log "INFO" "  kubectl get svc -n triton-inference"
log "INFO" "=========================================="

