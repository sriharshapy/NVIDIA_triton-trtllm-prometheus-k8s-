#!/bin/bash
# Startup script for GCP H100 instance
# Installs dependencies and sets up Triton Inference Server

set -e

LOG_FILE="/var/log/trt-llm-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "TRT-LLM Setup Script Started"
echo "Timestamp: $(date)"
echo "=========================================="

# Update system
echo "[$(date)] Updating system packages..."
apt-get update -y

# Install NVIDIA drivers and CUDA (if not already installed)
if ! command -v nvidia-smi &> /dev/null; then
    echo "[$(date)] Installing NVIDIA drivers..."
    apt-get install -y nvidia-driver-535 nvidia-utils-535
fi

# Install Docker (if not installed)
if ! command -v docker &> /dev/null; then
    echo "[$(date)] Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

# Install NVIDIA Container Toolkit
if [ ! -f /usr/bin/nvidia-container-runtime ]; then
    echo "[$(date)] Installing NVIDIA Container Toolkit..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
        tee /etc/apt/sources.list.d/nvidia-docker.list
    apt-get update -y
    apt-get install -y nvidia-container-toolkit
    systemctl restart docker
fi

# Create directories
echo "[$(date)] Creating model directories..."
mkdir -p /models/qwen3_8b_trtllm
mkdir -p /models/qwen3_8b
mkdir -p /opt/triton/logs

# Set permissions
chmod -R 755 /models
chmod -R 755 /opt/triton

echo "[$(date)] Setup completed successfully!"
echo "=========================================="
echo "Next steps:"
echo "1. Upload your compiled TRT-LLM model to /models/qwen3_8b_trtllm"
echo "2. Upload Qwen 3 8B tokenizer to /models/qwen3_8b"
echo "3. Start Triton Inference Server"
echo "=========================================="

