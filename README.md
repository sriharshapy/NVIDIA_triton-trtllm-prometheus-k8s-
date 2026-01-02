# Qwen 3 8B Deployment with TRT-LLM and Triton

This repository contains a minimal deployment setup for **Qwen 3 8B** using:
- **NVIDIA TRT-LLM** for optimized inference
- **NVIDIA Triton Inference Server** for serving
- **Google Cloud Platform (GCP)** with **H100 1g GPU**
- **Mixed precision**: bfloat16 (bf16) and FP8 quantization

## Architecture

```
┌─────────────────┐
│  GCP H100 1g    │
│                 │
│  ┌───────────┐  │
│  │  Triton   │  │
│  │  Server   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ TRT-LLM   │  │
│  │ Engine    │  │
│  └───────────┘  │
└─────────────────┘
```

## Prerequisites

1. **GCP Account** with H100 quota
2. **Terraform** >= 1.0
3. **Google Cloud SDK** (gcloud CLI)
4. **Python 3.8+**
5. **NVIDIA TRT-LLM** installed (on build machine or GCP instance)
6. **Qwen 3 8B model** in HuggingFace format

## Quick Start

### Option 1: GitHub Actions (Recommended)

Automated deployment via GitHub Actions:

1. **Set up secrets** (see [`.github/GITHUB_SECRETS.md`](.github/GITHUB_SECRETS.md)):
   - `GCP_SA_KEY` - Service account JSON key
   - `GCP_PROJECT_ID` - Your GCP project ID

2. **Deploy infrastructure**:
   - Go to Actions → Deploy GCP Infrastructure
   - Run workflow: `gke` + `apply`

3. **Deploy to Kubernetes**:
   - Go to Actions → Deploy to Kubernetes
   - Run workflow: `deploy`

See [`.github/SETUP.md`](.github/SETUP.md) for detailed setup instructions.

### Option 2: Manual Deployment

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project details
```

### 3. Build TRT-LLM Model

```bash
cd trt-llm
python3 build_qwen3_8b.py \
    --model_path /path/to/qwen3-8b \
    --output_dir ./qwen3_8b_trtllm \
    --dtype bfloat16
```

This will:
- Convert Qwen 3 8B to TRT-LLM format
- Enable bfloat16 precision
- Enable FP8 quantization for KV cache
- Generate optimized inference engine

**Note**: Build takes 30-60 minutes depending on hardware.

### 4. Deploy Infrastructure

**Option A: Kubernetes Deployment (Recommended)**

```bash
# Create GKE cluster (or use existing cluster)
cd terraform/gke
terraform init && terraform apply

# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> --zone <zone>

# For non-GKE clusters, install GPU Operator first:
# cd ../../k8s && ./gpu-operator-install.sh

# Deploy to Kubernetes
cd ../../k8s
chmod +x deploy.sh
./deploy.sh

# Upload model files (see k8s/README.md for details)
```

**Note**: GKE has built-in GPU support - GPU Operator is **NOT needed** for GKE. See `k8s/GPU_OPERATOR.md` for details.

**Option B: Automated VM Deployment**

```bash
# On Linux/Mac, make scripts executable
chmod +x sh/*.sh triton/triton_server.sh

# Run deployment
./sh/deploy.sh
```

**Option C: Manual VM Deployment**

```bash
# Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Upload model files manually
gcloud compute scp --zone=<ZONE> --recurse \
    ./trt-llm/qwen3_8b_trtllm/ \
    <INSTANCE_NAME>:/models/qwen3_8b_trtllm/

# SSH and start Triton
gcloud compute ssh <INSTANCE_NAME> --zone=<ZONE>
# Then run: /opt/triton/triton_server.sh
```

**Option D: Docker Deployment**

```bash
cd triton
# Update docker-compose.yml with model paths
docker-compose up -d
```

The deployment script will:
1. Build TRT-LLM model (if model path provided)
2. Deploy GCP H100 instance/GKE cluster via Terraform
3. Upload model files to instance/PVC
4. Start Triton Inference Server

### 5. Test Inference

```bash
python3 sh/test_inference.py \
    --endpoint http://<INSTANCE_IP>:8000 \
    --model qwen3_8b \
    --prompt "Hello, how are you?"
```

## Directory Structure

```
.
├── trt-llm/
│   └── build_qwen3_8b.py          # TRT-LLM build script
├── triton/
│   ├── model_repository/
│   │   └── qwen3_8b/
│   │       └── config.pbtxt       # Triton model config
│   ├── triton_server.sh            # Triton startup script
│   ├── Dockerfile                  # Docker image
│   └── docker-compose.yml          # Docker Compose config
├── terraform/
│   ├── main.tf                      # VM infrastructure
│   ├── variables.tf                 # Terraform variables
│   ├── terraform.tfvars.example     # Example config
│   ├── startup_script.sh            # GCP instance setup
│   └── gke/
│       ├── main.tf                  # GKE cluster definition
│       ├── variables.tf             # GKE variables
│       └── terraform.tfvars.example # GKE example config
├── k8s/
│   ├── namespace.yaml               # K8s namespace
│   ├── configmap.yaml               # Triton config
│   ├── pvc.yaml                     # Persistent volume claim
│   ├── deployment.yaml              # Triton deployment
│   ├── service.yaml                 # K8s services
│   ├── ingress.yaml                 # Optional ingress
│   ├── deploy.sh                    # K8s deployment script
│   └── README.md                    # K8s deployment guide
├── sh/
│   ├── deploy.sh                    # VM deployment automation
│   ├── test_inference.py            # Inference test script
│   ├── monitor.sh                   # Monitoring script
│   └── setup_env.sh                 # Environment setup
└── README.md                        # This file
```

## Configuration

### TRT-LLM Build Parameters

- `--dtype`: Base precision (`bfloat16` or `float16`)
- `--no-fp8`: Disable FP8 quantization (enabled by default)
- `--max_batch_size`: Maximum batch size (default: 8)
- `--max_input_len`: Maximum input length (default: 2048)
- `--max_output_len`: Maximum output length (default: 2048)

### Triton Configuration

Edit `triton/model_repository/qwen3_8b/config.pbtxt` to adjust:
- `max_batch_size`: Maximum batch size
- `instance_group`: GPU allocation
- `dynamic_batching`: Batching configuration

### GCP Configuration

Edit `terraform/terraform.tfvars`:
- `project_id`: Your GCP project ID
- `zone`: GCP zone with H100 availability
- `instance_name`: Instance name
- `disk_size`: Boot disk size (GB)

## Mixed Precision Details

This deployment uses:
- **bfloat16 (bf16)**: Base precision for compute operations
- **FP8**: Quantization for KV cache to reduce memory usage

Benefits:
- Reduced memory footprint
- Faster inference
- Maintained model quality

## Logging

All scripts include comprehensive logging:
- **TRT-LLM build**: `trt_llm_build.log`
- **Triton server**: `logs/triton_*.log`
- **Deployment**: `logs/deploy_*.log`
- **Inference tests**: `inference_test.log`

## Monitoring

Triton metrics available at:
```
http://<INSTANCE_IP>:8002/metrics
```

## Troubleshooting

### Build Fails
- Verify CUDA and TRT-LLM installation
- Check GPU memory (need ~40GB+ for build)
- Review `trt_llm_build.log`

### Triton Won't Start
- Check model files in `/models/qwen3_8b_trtllm`
- Verify tokenizer in `/models/qwen3_8b`
- Review Triton logs: `logs/triton_*.log`

### Inference Errors
- Verify model is loaded: `curl http://<IP>:8000/v2/models/qwen3_8b/ready`
- Check GPU memory: `nvidia-smi`
- Review inference logs

## Cost Estimation

GCP H100 1g pricing (approximate):
- **On-demand**: ~$5-7/hour
- **Preemptible**: ~$1-2/hour (if available)

## Cleanup

```bash
cd terraform
terraform destroy
```

## References

- [NVIDIA TRT-LLM Documentation](https://nvidia.github.io/TensorRT-LLM/)
- [Triton Inference Server](https://github.com/triton-inference-server/server)
- [Qwen Models](https://github.com/QwenLM/Qwen)

## License

This deployment configuration is provided as-is for demonstration purposes.
