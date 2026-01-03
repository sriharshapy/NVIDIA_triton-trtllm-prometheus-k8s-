# TRT-LLM Production Deployment Platform

> Production-ready automation for deploying Large Language Models using NVIDIA TRT-LLM, Triton Inference Server, Kubernetes, and Prometheus on cloud infrastructure.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GCP](https://img.shields.io/badge/cloud-GCP-orange)](https://cloud.google.com)
[![Kubernetes](https://img.shields.io/badge/orchestration-Kubernetes-blue)](https://kubernetes.io)

## Overview

This project provides **production-ready automation** for deploying LLMs using the industry's gold-standard technology stack:

- **NVIDIA TRT-LLM** - Optimized inference engine for maximum performance
- **NVIDIA Triton Inference Server** - Production-grade model serving platform
- **Kubernetes** - Industry-standard container orchestration
- **Prometheus** - Comprehensive metrics and monitoring

Built with extensive automation to streamline LLM deployment on cloud infrastructure, reducing setup time from days to minutes.

> **Note**: Currently supports **Google Cloud Platform (GCP)** only. Multi-cloud support coming soon.

## Major Features

* **Infrastructure as Code** - Terraform-based automated infrastructure provisioning
* **CI/CD Automation** - GitHub Actions workflows for one-click deployment
* **Helm Chart Deployment** - Complete Kubernetes package with parameterized configuration
* **Multi-Component Architecture** - Triton, OpenWebUI, and Prometheus integration
* **Cost Optimization** - Spot instance support with up to 80% cost savings
* **Resource Management** - Automatic scaling, quotas, and limit ranges
* **Comprehensive Monitoring** - Prometheus metrics with automatic scraping
* **Model Optimization** - Automated TRT-LLM engine building with KV cache management

## Deploy in 3 Easy Steps

### Step 1: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

- `GCP_SA_KEY` - Service Account JSON key
- `GCP_PROJECT_ID` - Your GCP project ID
- `GCP_REGION` - GCP region (e.g., `us-central1`)
- `GCP_ZONE` - GCP zone (e.g., `us-central1-a`)
- `GKE_CLUSTER_NAME` - Desired cluster name

### Step 2: Deploy Infrastructure

Go to **Actions** → **Deploy GCP Infrastructure** → Run workflow:
- Select `deployment_type: gke`
- Select `action: apply`
- Click **Run workflow**

### Step 3: Deploy to Kubernetes

Go to **Actions** → **Deploy to Kubernetes** → Run workflow:
- Select `action: deploy`
- Click **Run workflow`

Service endpoints will be displayed in the workflow summary. Upload your model files to the PVC to complete the setup.

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

## Documentation

### Getting Started

* [QUICKSTART.md](QUICKSTART.md) - Quick start guide with step-by-step instructions
* [SETUP_COMMANDS.md](SETUP_COMMANDS.md) - Platform-specific setup commands (macOS, Windows, Linux)

### Deployment

* [k8s/README.md](k8s/README.md) - Kubernetes deployment guide
* [helm/qwen3-8b-triton/README.md](helm/qwen3-8b-triton/README.md) - Helm chart documentation and configuration

### Operations

* [COST_ANALYSIS.md](COST_ANALYSIS.md) - Cost estimation and optimization strategies
* [k8s/KUBERNETES_SERVICE_DNS.md](k8s/KUBERNETES_SERVICE_DNS.md) - Understanding Kubernetes service DNS

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Inference Engine** | NVIDIA TRT-LLM | Optimized LLM inference |
| **Model Serving** | NVIDIA Triton | Production model serving |
| **Orchestration** | Kubernetes (GKE) | Container orchestration |
| **Monitoring** | Prometheus | Metrics and observability |
| **Web UI** | OpenWebUI | User interface for LLM interaction |
| **Infrastructure** | Terraform | Infrastructure as Code |
| **Deployment** | Helm | Kubernetes package management |
| **CI/CD** | GitHub Actions | Automated workflows |

## Supported Models

Currently optimized for **Qwen 3 8B**. Easily adaptable to other models by modifying the build scripts and Triton configuration.

## Cost Optimization

* **Spot Instances** - Up to 80% cost savings on GPU nodes
* **Efficient Scaling** - Maximum 1 GPU node to control costs
* **Resource Quotas** - Prevent resource waste
* **Automatic Cleanup** - Easy infrastructure teardown

See [COST_ANALYSIS.md](COST_ANALYSIS.md) for detailed cost breakdown and optimization tips.

## Cleanup

### Via GitHub Actions

1. **Undeploy Kubernetes**: Actions → Deploy to Kubernetes → `action: undeploy`
2. **Destroy Infrastructure**: Actions → Deploy GCP Infrastructure → `action: destroy`

### Via Command Line

```bash
# Uninstall Helm release
helm uninstall qwen3-8b-triton -n triton-inference

# Destroy infrastructure
cd terraform/gke
terraform destroy
```

## Contributing

Contributions are welcome! Areas for improvement:

* Multi-cloud support (AWS, Azure)
* Additional model support
* Enhanced monitoring dashboards
* Cost optimization features
* Documentation improvements

## Reporting Problems, Asking Questions

We appreciate any feedback, questions, or bug reports. When posting issues in GitHub:

* Use minimal, complete, and verifiable examples
* Include relevant logs and error messages
* Specify your environment (GCP project, zone, cluster version)

For questions, please open a GitHub Discussion.

## For More Information

* [NVIDIA TRT-LLM Documentation](https://nvidia.github.io/TensorRT-LLM/)
* [NVIDIA Triton Inference Server](https://github.com/triton-inference-server/server)
* [Kubernetes Documentation](https://kubernetes.io/docs/)
* [Prometheus Documentation](https://prometheus.io/docs/)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

* [NVIDIA TRT-LLM](https://nvidia.github.io/TensorRT-LLM/) - Inference optimization
* [NVIDIA Triton](https://github.com/triton-inference-server/server) - Model serving
* [OpenWebUI](https://github.com/open-webui/open-webui) - Web interface
* [Prometheus](https://prometheus.io/) - Monitoring

---

**Built for the LLM deployment community**
