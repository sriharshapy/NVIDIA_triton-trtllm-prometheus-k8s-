# Kubernetes Service DNS Explained

## Understanding `http://triton-qwen3-8b-internal:8000`

### What is this?

`http://triton-qwen3-8b-internal:8000` is a **Kubernetes internal service endpoint** that uses Kubernetes' built-in DNS system to resolve service names to IP addresses.

---

## How the Name is Decided

### 1. Service Name Construction

The service name `triton-qwen3-8b-internal` is built from:

```yaml
# In values.yaml
triton:
  name: triton-qwen3-8b  # Base name

# In triton-service.yaml template
name: {{ .Values.triton.name }}-internal
# Results in: "triton-qwen3-8b-internal"
```

**Service Definition:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: triton-qwen3-8b-internal  # ← This is the service name
  namespace: triton-inference
spec:
  type: ClusterIP  # Internal-only service
  ports:
  - port: 8000     # ← Service port
    targetPort: http
```

---

## Is This an Internal Domain Name?

**Yes!** It's Kubernetes' internal DNS system. Here's how it works:

### Kubernetes DNS Resolution

Kubernetes uses **CoreDNS** (or kube-dns) to provide DNS resolution for services. When you use a service name like `triton-qwen3-8b-internal`, Kubernetes automatically resolves it to the service's ClusterIP.

### DNS Resolution Hierarchy

When a pod tries to access `triton-qwen3-8b-internal:8000`, Kubernetes DNS tries these in order:

1. **Short name (same namespace):**
   ```
   triton-qwen3-8b-internal
   → Resolves to: <ClusterIP>:8000
   ```

2. **Fully qualified domain name (FQDN):**
   ```
   triton-qwen3-8b-internal.triton-inference.svc.cluster.local
   → Resolves to: <ClusterIP>:8000
   ```

3. **Cross-namespace access:**
   ```
   triton-qwen3-8b-internal.triton-inference.svc.cluster.local
   → Resolves to: <ClusterIP>:8000
   ```

---

## How It Works: Step by Step

### Step 1: Service Creation

When you deploy, Kubernetes creates a Service resource:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: triton-qwen3-8b-internal
  namespace: triton-inference
spec:
  type: ClusterIP  # Gets an internal IP (e.g., 10.96.123.45)
  selector:
    app: qwen3-8b
    component: triton-server
  ports:
  - port: 8000
    targetPort: 8000  # Port on the pod
```

**What happens:**
- Kubernetes assigns a **ClusterIP** (e.g., `10.96.123.45`)
- The service name is registered in CoreDNS
- The service routes traffic to pods matching the selector

### Step 2: DNS Registration

CoreDNS automatically creates DNS records:

```
triton-qwen3-8b-internal.triton-inference.svc.cluster.local → 10.96.123.45
```

### Step 3: Pod DNS Configuration

Every pod gets DNS configuration pointing to CoreDNS:

```bash
# Inside any pod, /etc/resolv.conf contains:
nameserver 10.96.0.10  # CoreDNS service IP
search triton-inference.svc.cluster.local svc.cluster.local cluster.local
```

### Step 4: DNS Resolution

When OpenWebUI pod tries to connect to `triton-qwen3-8b-internal:8000`:

1. **DNS Query:** Pod asks CoreDNS: "What is `triton-qwen3-8b-internal`?"
2. **DNS Response:** CoreDNS returns: `10.96.123.45`
3. **Connection:** Pod connects to `10.96.123.45:8000`
4. **Service Proxy:** Service routes to one of the backend pods (e.g., `10.244.1.5:8000`)

---

## Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│ OpenWebUI Pod (10.244.1.3)                                  │
│                                                              │
│  Makes request to:                                          │
│  http://triton-qwen3-8b-internal:8000                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 1. DNS Query
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ CoreDNS (10.96.0.10)                                        │
│                                                              │
│  Resolves:                                                  │
│  triton-qwen3-8b-internal                                   │
│  → 10.96.123.45 (ClusterIP)                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 2. DNS Response
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Service: triton-qwen3-8b-internal                           │
│ ClusterIP: 10.96.123.45                                     │
│                                                              │
│  Routes to backend pods:                                    │
│  - 10.244.1.5:8000 (Triton Pod)                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 3. Traffic Routing
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Triton Pod (10.244.1.5)                                     │
│                                                              │
│  Receives request on port 8000                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Why Two Services?

We have **two services** for Triton:

### 1. `triton-qwen3-8b` (LoadBalancer)
```yaml
type: LoadBalancer
```
- **Purpose:** External access from outside the cluster
- **Gets:** External IP address (e.g., `35.123.45.67`)
- **Accessible from:** Internet, external clients
- **Use case:** Testing, direct API calls from your machine

### 2. `triton-qwen3-8b-internal` (ClusterIP)
```yaml
type: ClusterIP
```
- **Purpose:** Internal cluster communication
- **Gets:** Internal ClusterIP (e.g., `10.96.123.45`)
- **Accessible from:** Only pods within the cluster
- **Use case:** OpenWebUI connecting to Triton (same cluster)

---

## DNS Name Formats

### Same Namespace (Short Form)
```bash
# From a pod in triton-inference namespace
curl http://triton-qwen3-8b-internal:8000
```

### Different Namespace (FQDN)
```bash
# From a pod in default namespace
curl http://triton-qwen3-8b-internal.triton-inference.svc.cluster.local:8000
```

### External Access (LoadBalancer)
```bash
# From outside the cluster
curl http://35.123.45.67:8000  # External IP
```

---

## Verification Commands

### Check Service DNS Resolution

```bash
# From inside a pod
nslookup triton-qwen3-8b-internal

# Output:
# Name:    triton-qwen3-8b-internal.triton-inference.svc.cluster.local
# Address: 10.96.123.45
```

### Check Service Details

```bash
# Get service information
kubectl get svc triton-qwen3-8b-internal -n triton-inference

# Output:
# NAME                        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
# triton-qwen3-8b-internal     ClusterIP   10.96.123.45  <none>        8000/TCP,8001/TCP,8002/TCP
```

### Test DNS from Pod

```bash
# Run a test pod
kubectl run -it --rm debug --image=busybox --restart=Never -n triton-inference -- sh

# Inside the pod, test DNS
nslookup triton-qwen3-8b-internal

# Test connectivity
wget -O- http://triton-qwen3-8b-internal:8000/v2/health/live
```

---

## Key Takeaways

1. **Service Name = DNS Name:** The service `metadata.name` becomes the DNS name
2. **Automatic Resolution:** Kubernetes CoreDNS automatically resolves service names
3. **Internal Only:** ClusterIP services are only accessible within the cluster
4. **Namespace Scoping:** Short names work within the same namespace
5. **FQDN Required:** Cross-namespace access needs the full FQDN
6. **Port Mapping:** Service port (8000) → Pod targetPort (8000)

---

## Configuration in Our Chart

### values.yaml
```yaml
triton:
  name: triton-qwen3-8b  # Base service name
  
  service:
    internal:
      enabled: true      # Creates the -internal service
      type: ClusterIP   # Internal-only access
```

### Result
- **External Service:** `triton-qwen3-8b` (LoadBalancer)
- **Internal Service:** `triton-qwen3-8b-internal` (ClusterIP)
- **OpenWebUI uses:** `http://triton-qwen3-8b-internal:8000` (internal)

---

## Summary

`http://triton-qwen3-8b-internal:8000` is:
- ✅ A Kubernetes service name (not a real domain)
- ✅ Resolved by CoreDNS to a ClusterIP
- ✅ Only accessible from within the cluster
- ✅ Automatically configured when the service is created
- ✅ Uses the service's `metadata.name` as the DNS name

This is Kubernetes' built-in service discovery mechanism - no external DNS or manual IP configuration needed!

