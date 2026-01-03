# TRT-LLM Production Deployment Platform

> **Industry-standard LLM deployment automation** using NVIDIA TRT-LLM, Triton Inference Server, Kubernetes, and Prometheus.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GCP](https://img.shields.io/badge/cloud-GCP-orange)](https://cloud.google.com)
[![Kubernetes](https://img.shields.io/badge/orchestration-Kubernetes-blue)](https://kubernetes.io)

## Overview

Production-ready automation for deploying Large Language Models using the industry's gold-standard stack:

- **NVIDIA TRT-LLM** - Optimized inference engine
- **NVIDIA Triton** - Production model serving
- **Kubernetes** - Container orchestration
- **Prometheus** - Metrics and monitoring

Built with extensive automation to streamline LLM deployment on cloud infrastructure.

> **Note**: Currently supports **Google Cloud Platform (GCP)** only.

## Capabilities

### Infrastructure Automation
- Terraform-based Infrastructure as Code
- Automated GKE cluster provisioning with GPU node pools
- Spot instance support for cost optimization
- GitHub Actions CI/CD workflows

### Model Optimization
- Automated TRT-LLM engine building
- KV cache size optimization
- Batch size and sequence length tuning
- Precision optimization (bf16 for A100)

### Kubernetes Deployment
- Helm chart-based deployment
- Multi-component architecture (Triton, OpenWebUI, Prometheus)
- Resource quotas and limit ranges
- Automatic PVC management

### Monitoring & Observability
- Prometheus integration with automatic metrics scraping
- Comprehensive logging across all components
- Health checks and readiness probes

### Cost Optimization
- Spot instance support (up to 80% savings)
- Efficient resource utilization
- Automatic scaling controls

## Quick Start

### Prerequisites
- GCP Account with A100 GPU quota
- GitHub Repository with Actions enabled

### Deployment Steps

1. **Configure GitHub Secrets**:
   - `GCP_SA_KEY` - Service Account JSON key
   - `GCP_PROJECT_ID` - Your GCP project ID
   - `GCP_REGION` - GCP region (e.g., `us-central1`)
   - `GCP_ZONE` - GCP zone (e.g., `us-central1-a`)
   - `GKE_CLUSTER_NAME` - Cluster name

2. **Deploy Infrastructure**:
   - Go to **Actions** → **Deploy GCP Infrastructure**
   - Select: `deployment_type: gke`, `action: apply`
   - Run workflow

3. **Deploy to Kubernetes**:
   - Go to **Actions** → **Deploy to Kubernetes**
   - Select: `action: deploy`
   - Run workflow

4. **Access Services**:
   - Service endpoints displayed in workflow summary
   - Upload model files to PVC (see [k8s/README.md](k8s/README.md))

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

## Architecture

```
┌─────────────────────────────────────┐
│         GKE Cluster                 │
│                                     │
│  ┌──────────────┐  ┌─────────────┐ │
│  │ A100 GPU Node│  │  CPU Nodes  │ │
│  │              │  │             │ │
│  │  ┌────────┐  │  │ ┌─────────┐ │ │
│  │  │ Triton │  │  │ │OpenWebUI│ │ │
│  │  │ Server │◄─┼──┼─│         │ │ │
│  │  └───┬────┘  │  │ └─────────┘ │ │
│  │      │       │  │             │ │
│  │  ┌───▼────┐  │  │ ┌─────────┐ │ │
│  │  │TRT-LLM │  │  │ │Prometheus│ │ │
│  │  │ Engine │  │  │ └─────────┘ │ │
│  │  └────────┘  │  └─────────────┘ │
│  └──────────────┘                  │
└─────────────────────────────────────┘
```

## Technology Stack

- **Inference**: NVIDIA TRT-LLM
- **Serving**: NVIDIA Triton
- **Orchestration**: Kubernetes (GKE)
- **Monitoring**: Prometheus
- **Web UI**: OpenWebUI
- **Infrastructure**: Terraform
- **Deployment**: Helm
- **CI/CD**: GitHub Actions

## Documentation

- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [k8s/README.md](k8s/README.md) - Kubernetes deployment
- [helm/qwen3-8b-triton/README.md](helm/qwen3-8b-triton/README.md) - Helm chart docs
- [COST_ANALYSIS.md](COST_ANALYSIS.md) - Cost estimation

## Supported Models

Currently optimized for **Qwen 3 8B**. Easily adaptable to other models.

## Cost Optimization

- Spot instances: Up to 80% cost savings
- Efficient scaling: Maximum 1 GPU node
- Automatic cleanup: Easy teardown

See [COST_ANALYSIS.md](COST_ANALYSIS.md) for details.

## Cleanup

### Via GitHub Actions
1. **Undeploy Kubernetes**: Actions → Deploy to Kubernetes → `undeploy`
2. **Destroy Infrastructure**: Actions → Deploy GCP Infrastructure → `destroy`

### Via Command Line
```bash
helm uninstall qwen3-8b-triton -n triton-inference
cd terraform/gke && terraform destroy
```

## Contributing

Contributions welcome! Areas for improvement:
- Multi-cloud support (AWS, Azure)
- Additional model support
- Enhanced monitoring
- Documentation improvements

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [NVIDIA TRT-LLM](https://nvidia.github.io/TensorRT-LLM/)
- [NVIDIA Triton](https://github.com/triton-inference-server/server)
- [OpenWebUI](https://github.com/open-webui/open-webui)
- [Prometheus](https://prometheus.io/)

---

**Built for the LLM deployment community**
