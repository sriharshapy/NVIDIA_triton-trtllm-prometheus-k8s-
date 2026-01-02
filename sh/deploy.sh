#!/bin/bash
# Deployment script for Qwen 3 8B with TRT-LLM and Triton

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log "INFO" "=========================================="
log "INFO" "Qwen 3 8B Deployment Script"
log "INFO" "=========================================="

# Check prerequisites
log "INFO" "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    log "ERROR" "Terraform not found. Please install Terraform."
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    log "ERROR" "gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

log "INFO" "✓ Prerequisites check passed"

# Step 1: Build TRT-LLM model
log "INFO" "Step 1: Building TRT-LLM model..."
if [ -f "$PROJECT_ROOT/trt-llm/build_qwen3_8b.py" ]; then
    log "INFO" "Running TRT-LLM build script..."
    cd "$PROJECT_ROOT/trt-llm"
    python3 build_qwen3_8b.py \
        --model_path "${MODEL_PATH:-/path/to/qwen3-8b}" \
        --output_dir "./qwen3_8b_trtllm" \
        2>&1 | tee -a "$LOG_FILE"
    log "INFO" "✓ TRT-LLM build completed"
else
    log "WARNING" "TRT-LLM build script not found. Skipping build step."
fi

# Step 2: Deploy infrastructure
log "INFO" "Step 2: Deploying GCP infrastructure..."
cd "$PROJECT_ROOT/terraform"

if [ ! -f "terraform.tfvars" ]; then
    log "ERROR" "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
    exit 1
fi

log "INFO" "Initializing Terraform..."
terraform init 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Planning Terraform deployment..."
terraform plan -out=tfplan 2>&1 | tee -a "$LOG_FILE"

log "INFO" "Applying Terraform configuration..."
terraform apply tfplan 2>&1 | tee -a "$LOG_FILE"

INSTANCE_IP=$(terraform output -raw instance_ip)
INSTANCE_ZONE=$(terraform output -raw instance_zone)

log "INFO" "✓ Infrastructure deployed"
log "INFO" "Instance IP: $INSTANCE_IP"
log "INFO" "Instance Zone: $INSTANCE_ZONE"

# Step 3: Upload model files
log "INFO" "Step 3: Uploading model files to instance..."
log "INFO" "Waiting for instance to be ready (30 seconds)..."
sleep 30

if [ -d "$PROJECT_ROOT/trt-llm/qwen3_8b_trtllm" ]; then
    log "INFO" "Uploading TRT-LLM model..."
    gcloud compute scp \
        --zone="$INSTANCE_ZONE" \
        --recurse \
        "$PROJECT_ROOT/trt-llm/qwen3_8b_trtllm/" \
        "qwen3-8b-h100:/models/qwen3_8b_trtllm/" \
        2>&1 | tee -a "$LOG_FILE"
    log "INFO" "✓ Model uploaded"
else
    log "WARNING" "Model directory not found. Please upload manually."
fi

# Step 4: Start Triton server
log "INFO" "Step 4: Starting Triton Inference Server..."
gcloud compute ssh \
    --zone="$INSTANCE_ZONE" \
    "qwen3-8b-h100" \
    --command="cd /opt/triton && nohup ./triton_server.sh > /opt/triton/logs/triton.log 2>&1 &" \
    2>&1 | tee -a "$LOG_FILE"

log "INFO" "✓ Deployment completed!"
log "INFO" "=========================================="
log "INFO" "Triton Inference Server should be running at:"
log "INFO" "  HTTP: http://$INSTANCE_IP:8000"
log "INFO" "  gRPC: $INSTANCE_IP:8001"
log "INFO" "  Metrics: http://$INSTANCE_IP:8002/metrics"
log "INFO" "=========================================="

