#!/bin/bash
# Environment setup script for TRT-LLM deployment

set -e

LOG_FILE="./logs/setup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p ./logs

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Environment Setup Script"
log "=========================================="

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    log "✓ Python found: $PYTHON_VERSION"
else
    log "✗ Python 3 not found. Please install Python 3.8+"
    exit 1
fi

# Install Python dependencies
log "Installing Python dependencies..."
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
log "✓ Python dependencies installed"

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n 1)
    log "✓ Terraform found: $TERRAFORM_VERSION"
else
    log "✗ Terraform not found. Please install Terraform >= 1.0"
    log "  Download from: https://www.terraform.io/downloads"
fi

# Check gcloud
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(Google Cloud SDK)")
    log "✓ gcloud CLI found: $GCLOUD_VERSION"
    
    # Check authentication
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)
        log "✓ Authenticated as: $ACTIVE_ACCOUNT"
    else
        log "⚠ Not authenticated. Run: gcloud auth login"
    fi
else
    log "✗ gcloud CLI not found. Please install Google Cloud SDK"
    log "  Download from: https://cloud.google.com/sdk/docs/install"
fi

# Check Docker (optional)
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log "✓ Docker found: $DOCKER_VERSION"
else
    log "⚠ Docker not found (optional for containerized deployment)"
fi

# Create necessary directories
log "Creating directories..."
mkdir -p logs
mkdir -p trt-llm/qwen3_8b_trtllm
mkdir -p triton/logs
log "✓ Directories created"

log "=========================================="
log "Environment setup completed!"
log "=========================================="

