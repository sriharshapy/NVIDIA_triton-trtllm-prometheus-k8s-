# Kubernetes Deployment for Qwen 3 8B

This directory contains Kubernetes manifests for deploying Qwen 3 8B with Triton Inference Server on GKE with A100 GPUs.

## Prerequisites

1. **Kubernetes Cluster** with A100 GPU nodes
   - **GKE**: Built-in GPU support (no GPU operator needed) ✅
   - **Other platforms**: Install GPU Operator (see `GPU_OPERATOR.md`)
2. **kubectl** configured to connect to your cluster
3. **Model files** ready to upload (TRT-LLM engine and tokenizer)
4. **Helm** (only if installing GPU Operator for non-GKE clusters)

## Quick Start

### 1. Create GKE Cluster (if not exists)

```bash
cd ../terraform/gke
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply

# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> --zone <zone>
```

**Note**: For **non-GKE clusters**, install GPU Operator first:
```bash
chmod +x gpu-operator-install.sh
./gpu-operator-install.sh
```
See `GPU_OPERATOR.md` for details.

### 2. Deploy to Kubernetes

```bash
cd k8s
chmod +x deploy.sh undeploy.sh

# Deploy
./deploy.sh

# Or deploy manually
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 3. Upload Model Files

```bash
# Wait for PVC to be ready
kubectl get pvc -n triton-inference

# Create a temporary pod
kubectl run -it --rm upload-pod \
    --image=busybox \
    --restart=Never \
    -n triton-inference \
    --overrides='
{
  "spec": {
    "containers": [{
      "name": "upload-pod",
      "image": "busybox",
      "command": ["sleep", "3600"],
      "volumeMounts": [{
        "mountPath": "/models",
        "name": "model-storage"
      }]
    }],
    "volumes": [{
      "name": "model-storage",
      "persistentVolumeClaim": {
        "claimName": "model-storage"
      }
    }]
  }
}'

# In another terminal, copy files
kubectl cp <local-model-path>/qwen3_8b_trtllm triton-inference/upload-pod:/models/qwen3_8b_trtllm
kubectl cp <local-tokenizer-path> triton-inference/upload-pod:/models/qwen3_8b
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n triton-inference

# Check services
kubectl get svc -n triton-inference

# View logs
kubectl logs -n triton-inference -l app=qwen3-8b -f

# Get external IP
kubectl get svc triton-qwen3-8b -n triton-inference
```

### 5. Test Inference

```bash
# Get external IP
EXTERNAL_IP=$(kubectl get svc triton-qwen3-8b -n triton-inference -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test
python3 ../sh/test_inference.py \
    --endpoint http://$EXTERNAL_IP:8000 \
    --model qwen3_8b \
    --prompt "Hello, how are you?"
```

## Files

- `namespace.yaml` - Kubernetes namespace
- `configmap.yaml` - Triton configuration
- `pvc.yaml` - Persistent volume claim for model storage
- `deployment.yaml` - Triton server deployment
- `service.yaml` - LoadBalancer and ClusterIP services
- `ingress.yaml` - Optional ingress configuration
- `kustomization.yaml` - Kustomize configuration
- `deploy.sh` - Automated deployment script
- `undeploy.sh` - Cleanup script

## Configuration

### Resource Limits

Edit `deployment.yaml` to adjust:
- GPU requests/limits
- CPU and memory
- Replica count

### Storage

Edit `pvc.yaml` to adjust:
- Storage size (default: 500Gi)
- Storage class (default: premium-rwo)

### Service Type

Edit `service.yaml` to change:
- `LoadBalancer` for external access
- `ClusterIP` for internal access only

## Monitoring

### View Logs

```bash
# All pods
kubectl logs -n triton-inference -l app=qwen3-8b -f

# Specific pod
kubectl logs -n triton-inference <pod-name> -f

# Previous container (if restarted)
kubectl logs -n triton-inference <pod-name> --previous
```

### Check Metrics

```bash
# Port forward to metrics endpoint
kubectl port-forward -n triton-inference svc/triton-qwen3-8b 8002:8002

# Access metrics
curl http://localhost:8002/metrics
```

### Pod Status

```bash
# Describe pod
kubectl describe pod -n triton-inference -l app=qwen3-8b

# Check events
kubectl get events -n triton-inference --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod -n triton-inference -l app=qwen3-8b

# Common issues:
# - GPU not available: Check node pool has H100 GPUs
# - PVC not bound: Check storage class and quota
# - Image pull errors: Check image name and registry access
```

### Model Not Loading

```bash
# Check if model files exist in PVC
kubectl exec -n triton-inference <pod-name> -- ls -la /models

# Check Triton logs
kubectl logs -n triton-inference <pod-name> | grep -i error
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n triton-inference

# Check endpoints
kubectl get endpoints -n triton-inference

# Port forward for testing
kubectl port-forward -n triton-inference svc/triton-qwen3-8b 8000:8000
```

## Scaling

### Manual Scaling

```bash
kubectl scale deployment triton-qwen3-8b -n triton-inference --replicas=2
```

### Auto-scaling (HPA)

```bash
kubectl autoscale deployment triton-qwen3-8b \
    -n triton-inference \
    --cpu-percent=70 \
    --min=1 \
    --max=5
```

Note: Auto-scaling with GPUs requires careful consideration of GPU availability.

## Cleanup

```bash
# Undeploy
./undeploy.sh

# Or manually
kubectl delete -f .
```

## Cost Optimization

- Use **preemptible nodes** for development
- Set **min_node_count=0** to scale down when not in use
- Use **ClusterIP** service type if external access not needed
- Monitor resource usage and adjust limits

## Security

- Use **Workload Identity** for GCP service accounts
- Enable **network policies** for pod-to-pod communication
- Use **secrets** for sensitive configuration (not included in this setup)
- Enable **Pod Security Standards** in production

