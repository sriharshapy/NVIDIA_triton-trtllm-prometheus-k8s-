# GitHub Actions Quick Reference

## Required Secrets (Minimum)

```bash
# 1. Create service account key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@PROJECT_ID.iam.gserviceaccount.com

# 2. Add to GitHub:
#    Settings → Secrets → Actions → New repository secret
```

| Secret | Value |
|--------|-------|
| `GCP_SA_KEY` | Full contents of `github-actions-key.json` |
| `GCP_PROJECT_ID` | Your GCP project ID |

## Workflow Commands

### Deploy Infrastructure
```
Actions → Deploy GCP Infrastructure → Run workflow
  - Deployment type: gke | vm
  - Action: plan | apply | destroy
```

### Deploy to Kubernetes
```
Actions → Deploy to Kubernetes → Run workflow
  - Action: deploy | undeploy
```

## Quick Setup (One-time)

```bash
# 1. Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions" \
    --project=YOUR_PROJECT_ID

# 2. Grant permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# 3. Create key
gcloud iam service-accounts keys create key.json \
    --iam-account=github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. Add to GitHub Secrets:
#    - GCP_SA_KEY: (contents of key.json)
#    - GCP_PROJECT_ID: YOUR_PROJECT_ID
```

## Typical Workflow

1. **Plan** → Review changes
2. **Apply** → Create infrastructure
3. **Deploy K8s** → Deploy Triton
4. **Test** → Verify endpoints
5. **Destroy** → Clean up (when done)

## Common Issues

| Issue | Solution |
|-------|----------|
| Auth failed | Check `GCP_SA_KEY` is valid JSON |
| Permission denied | Verify IAM roles assigned |
| Zone unavailable | Check H100 quota/availability |
| Cluster not found | Verify `GKE_CLUSTER_NAME` matches |

