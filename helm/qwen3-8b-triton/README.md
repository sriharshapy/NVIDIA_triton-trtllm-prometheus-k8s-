# Qwen 3 8B Triton Helm Chart

This Helm chart deploys Qwen 3 8B with NVIDIA Triton Inference Server, OpenWebUI, and Prometheus on Kubernetes.

## Prerequisites

- Kubernetes cluster (GKE recommended)
- Helm 3.x installed
- kubectl configured to access your cluster
- GPU nodes available (A100 40GB for this deployment)

## Installation

### Quick Start

```bash
# Install the chart
helm install qwen3-8b-triton ./helm/qwen3-8b-triton \
  --namespace triton-inference \
  --create-namespace \
  --wait

# Check deployment status
kubectl get pods -n triton-inference
```

### Custom Configuration

You can override default values:

```bash
helm install qwen3-8b-triton ./helm/qwen3-8b-triton \
  --namespace triton-inference \
  --create-namespace \
  --set triton.replicas=1 \
  --set triton.storage.size=500Gi \
  --set openwebui.enabled=true \
  --set prometheus.enabled=true
```

Or use a custom values file:

```bash
helm install qwen3-8b-triton ./helm/qwen3-8b-triton \
  --namespace triton-inference \
  --create-namespace \
  -f my-values.yaml
```

## Configuration

Key configuration options in `values.yaml`:

### Triton Inference Server

- `triton.enabled`: Enable/disable Triton deployment
- `triton.replicas`: Number of Triton replicas (default: 1)
- `triton.image.repository`: Container image repository
- `triton.image.tag`: Container image tag
- `triton.storage.size`: PVC size for model storage
- `triton.resources`: Resource requests and limits

### OpenWebUI

- `openwebui.enabled`: Enable/disable OpenWebUI
- `openwebui.replicas`: Number of OpenWebUI replicas
- `openwebui.config`: OpenWebUI configuration

### Prometheus

- `prometheus.enabled`: Enable/disable Prometheus
- `prometheus.storage.size`: PVC size for metrics storage
- `prometheus.config`: Prometheus scrape configuration

## Upgrading

```bash
# Upgrade with new values
helm upgrade qwen3-8b-triton ./helm/qwen3-8b-triton \
  --namespace triton-inference \
  --set triton.image.tag=24.12-trtllm-python-py3

# View current values
helm get values qwen3-8b-triton -n triton-inference
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall qwen3-8b-triton --namespace triton-inference

# Optionally delete the namespace
kubectl delete namespace triton-inference
```

## Model Upload

After deployment, upload your model files to the PVC:

1. Enable the upload job:
```bash
helm upgrade qwen3-8b-triton ./helm/qwen3-8b-triton \
  --namespace triton-inference \
  --set uploadJob.enabled=true
```

2. Get the pod name:
```bash
kubectl get pods -n triton-inference -l component=model-upload
```

3. Copy model files:
```bash
kubectl cp <local-path>/qwen3_8b_trtllm triton-inference/<pod-name>:/models/qwen3_8b_trtllm
kubectl cp <local-path>/qwen3_8b triton-inference/<pod-name>:/models/qwen3_8b
```

## Accessing Services

After deployment, get service endpoints:

```bash
# Get LoadBalancer IPs
kubectl get svc -n triton-inference

# Triton endpoints
TRITON_IP=$(kubectl get svc triton-qwen3-8b -n triton-inference -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Triton HTTP: http://$TRITON_IP:8000"
echo "Triton gRPC: $TRITON_IP:8001"
echo "Triton Metrics: http://$TRITON_IP:8002/metrics"

# OpenWebUI
OPENWEBUI_IP=$(kubectl get svc openwebui -n triton-inference -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "OpenWebUI: http://$OPENWEBUI_IP"

# Prometheus
PROMETHEUS_IP=$(kubectl get svc prometheus -n triton-inference -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus: http://$PROMETHEUS_IP:9090"
```

## Troubleshooting

### Check Pod Logs

```bash
# Triton logs
kubectl logs -n triton-inference deployment/triton-qwen3-8b

# OpenWebUI logs
kubectl logs -n triton-inference deployment/openwebui

# Prometheus logs
kubectl logs -n triton-inference deployment/prometheus
```

### Check PVC Status

```bash
kubectl get pvc -n triton-inference
```

### Describe Resources

```bash
# Describe deployment
kubectl describe deployment triton-qwen3-8b -n triton-inference

# Describe service
kubectl describe svc triton-qwen3-8b -n triton-inference
```

## Chart Structure

```
helm/qwen3-8b-triton/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── templates/              # Kubernetes manifest templates
│   ├── _helpers.tpl        # Template helpers
│   ├── namespace.yaml      # Namespace
│   ├── resource-quota.yaml # Resource quotas
│   ├── limit-range.yaml    # Limit ranges
│   ├── triton-*.yaml       # Triton resources
│   ├── openwebui-*.yaml    # OpenWebUI resources
│   ├── prometheus-*.yaml   # Prometheus resources
│   └── upload-job.yaml     # Model upload job
└── README.md               # This file
```

## Values Reference

See `values.yaml` for all available configuration options. Key sections:

- `global`: Global settings (namespace, app name)
- `namespace`: Namespace configuration
- `resourceQuota`: Resource quota settings
- `limitRange`: Limit range settings
- `triton`: Triton Inference Server configuration
- `openwebui`: OpenWebUI configuration
- `prometheus`: Prometheus configuration
- `uploadJob`: Model upload job configuration

## Support

For issues and questions, please refer to the main project README.md.

