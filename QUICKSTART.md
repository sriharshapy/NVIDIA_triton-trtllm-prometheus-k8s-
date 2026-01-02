# Quick Start Guide

## Prerequisites Checklist

- [ ] GCP account with H100 quota
- [ ] Terraform installed (>= 1.0)
- [ ] Google Cloud SDK installed
- [ ] Python 3.8+ installed
- [ ] Qwen 3 8B model downloaded (HuggingFace format)

## Step-by-Step Deployment

### 1. Environment Setup

```bash
# Install Python dependencies
pip install -r requirements.txt

# Or run setup script (Linux/Mac)
chmod +x sh/setup_env.sh
./sh/setup_env.sh
```

### 2. Configure GCP

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
```

### 3. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings:
# - project_id: Your GCP project ID
# - zone: Zone with H100 availability (e.g., us-central1-a)
```

### 4. Build TRT-LLM Model

**Option A: Build on local machine (if you have GPU)**

```bash
cd trt-llm
python3 build_qwen3_8b.py \
    --model_path /path/to/Qwen/Qwen2.5-8B-Instruct \
    --output_dir ./qwen3_8b_trtllm \
    --dtype bfloat16
```

**Option B: Build on GCP instance**

1. Create a temporary GPU instance
2. Install TRT-LLM
3. Run build script
4. Download compiled model

### 5. Deploy

**Automated (Linux/Mac):**

```bash
chmod +x sh/deploy.sh
./sh/deploy.sh
```

**Manual:**

```bash
# Deploy infrastructure
cd terraform
terraform init
terraform apply

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_ip)
INSTANCE_ZONE=$(terraform output -raw instance_zone)

# Upload model
gcloud compute scp --zone=$INSTANCE_ZONE --recurse \
    trt-llm/qwen3_8b_trtllm/ \
    qwen3-8b-h100:/models/qwen3_8b_trtllm/

# Upload tokenizer
gcloud compute scp --zone=$INSTANCE_ZONE --recurse \
    /path/to/qwen3-8b/tokenizer_files/ \
    qwen3-8b-h100:/models/qwen3_8b/

# SSH and start Triton
gcloud compute ssh --zone=$INSTANCE_ZONE qwen3-8b-h100
# Then run:
cd /opt/triton
./triton_server.sh
```

### 6. Test

```bash
# Wait for Triton to start (30-60 seconds)
sleep 60

# Test inference
python3 sh/test_inference.py \
    --endpoint http://$INSTANCE_IP:8000 \
    --model qwen3_8b \
    --prompt "What is machine learning?"
```

## Verification

### Check Triton Health

```bash
curl http://$INSTANCE_IP:8000/v2/health/ready
```

### Check Model Status

```bash
curl http://$INSTANCE_IP:8000/v2/models/qwen3_8b/ready
```

### View Metrics

```bash
curl http://$INSTANCE_IP:8002/metrics
```

## Troubleshooting

### Build Issues

- **Out of memory**: Reduce `max_batch_size` or `max_input_len`
- **CUDA errors**: Verify CUDA/TRT-LLM installation
- **Model not found**: Check model path is correct

### Deployment Issues

- **Terraform errors**: Verify GCP credentials and project ID
- **Instance won't start**: Check H100 quota in selected zone
- **SSH fails**: Wait 2-3 minutes after instance creation

### Triton Issues

- **Model not loading**: Check model files in `/models/`
- **Port conflicts**: Change ports in `triton_server.sh`
- **GPU not detected**: Verify NVIDIA drivers on instance

## Next Steps

- Monitor inference metrics
- Tune batch sizes for your workload
- Set up load balancing for production
- Configure auto-scaling

## Cleanup

```bash
cd terraform
terraform destroy
```
