#!/bin/bash
# Triton Inference Server startup script for Qwen 3 8B

set -e

# Configure logging
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/triton_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Starting Triton Inference Server"
log "=========================================="

# Configuration
MODEL_REPO="${MODEL_REPO:-./model_repository}"
HTTP_PORT="${HTTP_PORT:-8000}"
GRPC_PORT="${GRPC_PORT:-8001}"
METRICS_PORT="${METRICS_PORT:-8002}"

log "Model repository: $MODEL_REPO"
log "HTTP port: $HTTP_PORT"
log "gRPC port: $GRPC_PORT"
log "Metrics port: $METRICS_PORT"

# Verify model repository exists
if [ ! -d "$MODEL_REPO" ]; then
    log "ERROR: Model repository not found: $MODEL_REPO"
    exit 1
fi

# Verify GPU availability
if command -v nvidia-smi &> /dev/null; then
    log "GPU Information:"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader | tee -a "$LOG_FILE"
else
    log "WARNING: nvidia-smi not found. GPU may not be available."
fi

# Start Triton server
log "Starting Triton Inference Server..."
log "Logs will be written to: $LOG_FILE"

tritonserver \
    --model-repository="$MODEL_REPO" \
    --http-port="$HTTP_PORT" \
    --grpc-port="$GRPC_PORT" \
    --metrics-port="$METRICS_PORT" \
    --log-verbose=1 \
    --log-info=true \
    --log-warning=true \
    --log-error=true \
    --exit-on-error=false \
    2>&1 | tee -a "$LOG_FILE"

log "Triton Inference Server stopped."

