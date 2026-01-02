# GCP Cost Analysis - Qwen 3 8B Deployment

## Infrastructure Components

### 1. GKE Cluster Management
- **Base cluster fee**: ~$0.10/hour
- **Monthly**: ~$73/month

### 2. A100 GPU Node Pool (Spot Instances) ⚡
- **Machine type**: `a2-highgpu-1g` (A100 40GB)
- **Instance**: ~$3.50-5.00/hour (on-demand)
- **Spot discount**: 60-80% off
- **Spot price**: ~$0.70-2.00/hour
- **GPU (A100 40GB)**: ~$2.50-3.50/hour (on-demand)
- **Spot GPU**: ~$0.50-1.40/hour (60-80% discount)
- **200GB SSD boot disk**: ~$0.04/hour
- **Total spot cost**: ~$1.24-3.44/hour
- **Monthly (24/7)**: ~$900-2,500/month

### 3. CPU Node Pool (OpenWebUI + Prometheus)
- **Machine type**: `e2-standard-2` (2 vCPU, 8GB RAM)
- **Instance**: ~$0.07-0.10/hour
- **30GB standard disk**: ~$0.004/hour
- **Total**: ~$0.074-0.104/hour
- **Monthly (24/7)**: ~$54-76/month

### 4. Persistent Storage (PVCs)
- **Model storage**: 500GB SSD = ~$0.17/hour = ~$124/month
- **OpenWebUI data**: 10GB SSD = ~$0.003/hour = ~$2/month
- **Prometheus storage**: 20GB SSD = ~$0.007/hour = ~$5/month
- **Total storage**: ~$0.18/hour = ~$131/month

### 5. LoadBalancers (3 services)
- **Standard tier**: ~$0.025/hour each × 3 = ~$0.075/hour
- **Monthly**: ~$55/month
- **Data transfer**: Additional (varies by usage, typically $0.12/GB after free tier)

---

## Total Cost Breakdown

### With Spot Instances (Current Configuration) ⚡

| Component | Hourly Cost | Monthly Cost (24/7) |
|-----------|-------------|---------------------|
| GKE Cluster | $0.10 | $73 |
| **A100 GPU (Spot)** | **$1.24-3.44** | **$900-2,500** |
| CPU Node | $0.074-0.104 | $54-76 |
| Storage (PVCs) | $0.18 | $131 |
| LoadBalancers (3x) | $0.075 | $55 |
| **TOTAL** | **~$1.67-3.90/hour** | **~$1,213-2,835/month** |

### Without Spot Instances (On-Demand)

| Component | Hourly Cost | Monthly Cost (24/7) |
|-----------|-------------|---------------------|
| GKE Cluster | $0.10 | $73 |
| **A100 GPU (On-demand)** | **$6.00-8.50** | **$4,380-6,205** |
| CPU Node | $0.074-0.104 | $54-76 |
| Storage (PVCs) | $0.18 | $131 |
| LoadBalancers (3x) | $0.075 | $55 |
| **TOTAL** | **~$6.43-8.93/hour** | **~$4,693-6,540/month** |

---

## Cost Savings with Spot Instances

- **Hourly savings**: ~$4.76-5.03/hour (74-78% reduction)
- **Monthly savings**: ~$3,480-3,705/month
- **Annual savings**: ~$41,760-44,460/year

---

## Important Notes About Spot Instances

### ⚠️ Spot Instance Characteristics:
1. **Can be preempted**: GCP can reclaim spot instances with 30-second notice
2. **Availability varies**: Not always available in all zones
3. **Automatic restart**: GKE automatically reschedules pods to new nodes
4. **Best for**: Fault-tolerant workloads, development, testing

### ✅ Mitigation Strategies:
1. **Pod Disruption Budgets**: Already configured in your deployment
2. **Automatic rescheduling**: GKE handles pod migration automatically
3. **Stateful workloads**: Use PVCs (already configured) for persistence
4. **Monitoring**: Prometheus tracks interruptions

### 📊 Expected Interruption Rate:
- **Typical**: 5-15% of instances per month
- **Worst case**: Up to 30% in high-demand periods
- **Average downtime**: 2-5 minutes per interruption

---

## Cost Optimization Tips

### 1. **Committed Use Discounts (CUDs)**
- **1-year CUD**: Additional 30-40% off spot prices
- **3-year CUD**: Additional 50-60% off spot prices
- **Potential monthly cost**: ~$450-1,000/month (with 3-year CUD on spot)

### 2. **Scheduled Shutdowns**
- **8 hours/day**: ~$300-800/month (vs $900-2,500)
- **Weekends only**: ~$600-1,700/month
- **On-demand only**: Deploy when needed, destroy when idle

### 3. **Regional Pricing**
- **Cheaper regions**: `us-central1`, `us-west1`, `europe-west4`
- **Savings**: 10-20% compared to premium regions

### 4. **Storage Optimization**
- Use standard disks for non-critical data (Prometheus can use standard)
- Reduce model storage if possible (currently 500GB)

### 5. **LoadBalancer Optimization**
- Use Ingress instead of multiple LoadBalancers (saves ~$37/month)
- Consider internal LoadBalancers for non-public services

---

## Cost Scenarios

### Scenario 1: Development/Testing (8 hours/day, weekdays)
- **Monthly cost**: ~$300-800/month
- **Best for**: Development, testing, demos

### Scenario 2: Production (24/7 with spot)
- **Monthly cost**: ~$1,213-2,835/month
- **Best for**: Production workloads that can tolerate interruptions

### Scenario 3: Production (24/7 on-demand)
- **Monthly cost**: ~$4,693-6,540/month
- **Best for**: Critical workloads requiring guaranteed availability

### Scenario 4: Production (24/7 spot + 3-year CUD)
- **Monthly cost**: ~$450-1,000/month
- **Best for**: Long-term production with cost optimization

---

## Cost Monitoring

### GCP Cost Management:
1. **Billing Alerts**: Set up in GCP Console
2. **Budget Alerts**: Configure spending limits
3. **Cost Reports**: Review in GCP Billing Dashboard

### Recommended Budget Alerts:
- **Warning**: $1,500/month (spot) or $5,000/month (on-demand)
- **Critical**: $2,500/month (spot) or $6,500/month (on-demand)

---

## Summary

**Current Configuration (Spot Instances):**
- ✅ **60-80% cost savings** vs on-demand
- ✅ **~$1,213-2,835/month** for 24/7 operation
- ⚠️ **5-15% interruption rate** (acceptable for most workloads)
- ✅ **Automatic recovery** via GKE

**Recommendation:**
- Use **spot instances** for development, testing, and fault-tolerant production
- Consider **on-demand** only for critical workloads requiring 100% uptime
- Add **Committed Use Discounts** for additional 30-60% savings on long-term deployments

