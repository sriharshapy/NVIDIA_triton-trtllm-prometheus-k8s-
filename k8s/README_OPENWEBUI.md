# OpenWebUI Deployment

OpenWebUI is deployed as a separate service in the same GKE cluster, running on CPU nodes and connecting to the Triton inference server.

## Architecture

```
Internet
   │
   ├─→ OpenWebUI (LoadBalancer) → CPU Node Pool
   │                              │
   │                              └─→ Triton Service (ClusterIP) → GPU Node Pool
   │
   └─→ Triton (LoadBalancer) → GPU Node Pool
```

## Components

1. **OpenWebUI Deployment** (`openwebui-deployment.yaml`)
   - Runs on CPU nodes (separate from GPU nodes)
   - Connects to Triton service via internal ClusterIP
   - Persistent storage for user data

2. **OpenWebUI Service** (`openwebui-service.yaml`)
   - LoadBalancer for internet access
   - ClusterIP for internal communication

3. **OpenWebUI PVC** (`openwebui-pvc.yaml`)
   - 10Gi storage for user data and settings

4. **OpenWebUI ConfigMap** (`openwebui-configmap.yaml`)
   - Configuration for Triton connection

5. **CPU Node Pool** (in `terraform/gke/main.tf`)
   - Separate node pool for non-GPU workloads
   - e2-standard-4 (4 vCPU, 16GB RAM)
   - Auto-scaling: 0-2 nodes

## Deployment

OpenWebUI is automatically deployed when you run:

```bash
./k8s/deploy.sh
```

Or via GitHub Actions workflow.

## Configuration

### Connecting to Triton

OpenWebUI is configured to connect to Triton via:
- **Service**: `triton-qwen3-8b-internal` (ClusterIP)
- **Port**: `8000` (HTTP)
- **Model**: `qwen3_8b`

### Environment Variables

- `OPENAI_API_BASE_URL`: Triton service endpoint
- `OPENAI_API_KEY`: Not required (set to "not-required")
- `DEFAULT_MODEL`: `qwen3-8b`

## Access

After deployment, get the external IP:

```bash
kubectl get svc openwebui -n triton-inference
```

Access the web UI at: `http://<EXTERNAL_IP>`

## Node Selection

OpenWebUI runs on CPU nodes using:
- **Node Selector**: `accelerator: cpu`, `pool: cpu`
- **Toleration**: `workload-type=cpu:NoSchedule`

This ensures it doesn't run on expensive GPU nodes.

## Troubleshooting

### OpenWebUI can't connect to Triton

1. Check Triton service is running:
   ```bash
   kubectl get svc triton-qwen3-8b-internal -n triton-inference
   ```

2. Check OpenWebUI logs:
   ```bash
   kubectl logs -n triton-inference -l app=openwebui
   ```

3. Verify network connectivity:
   ```bash
   kubectl exec -n triton-inference <openwebui-pod> -- \
     curl http://triton-qwen3-8b-internal:8000/v2/health/ready
   ```

### External IP not assigned

1. Check service status:
   ```bash
   kubectl describe svc openwebui -n triton-inference
   ```

2. Check for LoadBalancer events:
   ```bash
   kubectl get events -n triton-inference --sort-by='.lastTimestamp'
   ```

### Pod not starting

1. Check if CPU nodes are available:
   ```bash
   kubectl get nodes -l accelerator=cpu
   ```

2. Check pod events:
   ```bash
   kubectl describe pod -n triton-inference -l app=openwebui
   ```

## Notes

- OpenWebUI uses OpenAI-compatible API format
- Triton may need an adapter/proxy for full OpenAI compatibility
- Consider using vLLM or similar if direct Triton connection doesn't work
- User data is persisted in PVC (survives pod restarts)

