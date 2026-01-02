# GPU Operator Requirements

## Do You Need the GPU Operator?

### **GKE (Google Kubernetes Engine): NO** ✅

**GKE has built-in GPU support** - When you create a GPU node pool in GKE, Google automatically:
- Installs NVIDIA device plugin
- Configures GPU drivers
- Sets up GPU runtime
- Exposes GPUs via `nvidia.com/gpu` resource

**Our current setup uses GKE, so GPU operator is NOT required.**

### **Other Kubernetes Platforms: YES** ⚠️

For **non-GKE** Kubernetes clusters, you **DO need** the NVIDIA GPU Operator:

- **On-premises Kubernetes**
- **Self-managed Kubernetes**
- **Other cloud providers** (AWS EKS, Azure AKS - though they may have their own solutions)
- **Local development clusters**

## What the GPU Operator Does

The NVIDIA GPU Operator automates:
1. **NVIDIA Device Plugin** - Exposes GPUs to Kubernetes
2. **NVIDIA Driver** - GPU driver installation
3. **Container Runtime** - GPU container runtime (nvidia-container-runtime)
4. **DCGM Exporter** - GPU metrics collection
5. **Node Feature Discovery** - Automatic GPU node labeling

## Installation for Non-GKE Clusters

If you're deploying to a non-GKE cluster, install the GPU Operator:

```bash
# Add NVIDIA Helm repository
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Install GPU Operator
helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator

# Verify installation
kubectl get pods -n gpu-operator
kubectl get nodes -o json | jq '.items[].status.allocatable | keys'
# Should show "nvidia.com/gpu" in the output
```

## Verifying GPU Support

Check if your cluster has GPU support:

```bash
# Check if nvidia.com/gpu resource is available
kubectl describe node <gpu-node-name> | grep nvidia.com/gpu

# Should show:
# nvidia.com/gpu:  1

# Check device plugin
kubectl get daemonset -n kube-system | grep nvidia
```

## Current Deployment Configuration

Our `deployment.yaml` uses:
```yaml
resources:
  requests:
    nvidia.com/gpu: 1
  limits:
    nvidia.com/gpu: 1
```

This works with:
- ✅ **GKE** (built-in support)
- ✅ **GPU Operator** (if installed)
- ✅ **Manual device plugin** (if configured)

## Troubleshooting

### Pod Stuck in Pending

```bash
# Check pod events
kubectl describe pod <pod-name> -n triton-inference

# Common issues:
# - "0/1 nodes are available: 1 Insufficient nvidia.com/gpu"
#   → GPU operator/device plugin not installed
# - "0/1 nodes are available: 1 node(s) didn't match node selector"
#   → No GPU nodes available
```

### GPU Not Detected

```bash
# Check node labels
kubectl get nodes --show-labels | grep gpu

# Check device plugin pods
kubectl get pods -n kube-system | grep nvidia

# Check node resources
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
```

## Summary

| Platform | GPU Operator Needed? | Notes |
|----------|---------------------|-------|
| **GKE** | ❌ **NO** | Built-in GPU support |
| **EKS** | ⚠️ **Maybe** | AWS provides NVIDIA device plugin |
| **AKS** | ⚠️ **Maybe** | Azure provides GPU support |
| **On-prem** | ✅ **YES** | Install GPU Operator |
| **Self-managed** | ✅ **YES** | Install GPU Operator |
| **Local (kind/minikube)** | ✅ **YES** | Install GPU Operator |

For our **GKE deployment**, you can proceed without GPU Operator installation.

