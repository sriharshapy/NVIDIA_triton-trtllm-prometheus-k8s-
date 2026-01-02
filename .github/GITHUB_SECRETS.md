# GitHub Secrets Configuration Guide

This document explains all the secrets you need to configure in GitHub for the CI/CD workflows.

## Required Secrets

### 1. `GCP_SA_KEY` (Required)

**Description**: Service Account JSON key for GCP authentication

**How to create**:
```bash
# 1. Create a service account (if not exists)
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=YOUR_PROJECT_ID

# 2. Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# Or use more specific roles:
# - roles/compute.admin (for VM deployment)
# - roles/container.admin (for GKE deployment)
# - roles/iam.serviceAccountUser
# - roles/storage.admin (if using GCS for models)

# 3. Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
    --project=YOUR_PROJECT_ID
```

**How to add to GitHub**:
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GCP_SA_KEY`
4. Value: Copy the entire contents of `github-actions-key.json` file
5. Click "Add secret"

**Security Note**: This key has full access. Consider using more restrictive roles in production.

---

### 2. `GCP_PROJECT_ID` (Required)

**Description**: Your GCP Project ID

**How to find**:
```bash
gcloud projects list
```

**How to add to GitHub**:
1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GCP_PROJECT_ID`
4. Value: Your project ID (e.g., `my-project-123456`)
5. Click "Add secret"

---

### 3. `GCP_REGION` (Optional)

**Description**: GCP region for deployment

**Default**: `us-central1`

**How to add to GitHub**:
1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GCP_REGION`
4. Value: Your preferred region (e.g., `us-central1`, `us-east1`)
5. Click "Add secret"

---

### 4. `GCP_ZONE` (Optional)

**Description**: GCP zone for deployment (must support H100 GPUs)

**Default**: `us-central1-a`

**How to find available zones**:
```bash
gcloud compute zones list --filter="name~us-central1"
```

**How to add to GitHub**:
1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GCP_ZONE`
4. Value: Your preferred zone (e.g., `us-central1-a`)
5. Click "Add secret"

---

### 5. `GKE_CLUSTER_NAME` (Optional, for K8s deployment)

**Description**: Name of your GKE cluster

**Default**: `trt-llm-cluster`

**How to add to GitHub**:
1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GKE_CLUSTER_NAME`
4. Value: Your cluster name
5. Click "Add secret"

---

## Quick Setup Script

You can use this script to automate secret creation:

```bash
#!/bin/bash
# setup-github-secrets.sh

PROJECT_ID="your-project-id"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="trt-llm-cluster"

# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=$PROJECT_ID

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# Create key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --project=$PROJECT_ID

echo "=========================================="
echo "GitHub Secrets to Add:"
echo "=========================================="
echo ""
echo "1. GCP_SA_KEY:"
echo "   Content of: github-actions-key.json"
echo ""
echo "2. GCP_PROJECT_ID:"
echo "   Value: $PROJECT_ID"
echo ""
echo "3. GCP_REGION (optional):"
echo "   Value: $REGION"
echo ""
echo "4. GCP_ZONE (optional):"
echo "   Value: $ZONE"
echo ""
echo "5. GKE_CLUSTER_NAME (optional):"
echo "   Value: $CLUSTER_NAME"
echo ""
echo "=========================================="
echo "Add these at:"
echo "https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
echo "=========================================="
```

---

## Minimum Required Secrets

For basic functionality, you only need:

1. ✅ **GCP_SA_KEY** - Service account JSON key
2. ✅ **GCP_PROJECT_ID** - Your GCP project ID

The others have sensible defaults.

---

## Environment Protection

For production deployments, consider using **GitHub Environments** with protection rules:

1. Go to Settings → Environments
2. Create a new environment called `production`
3. Add required reviewers
4. Add deployment branches (e.g., `main` only)
5. Add the secrets to the environment (they override repository secrets)

This ensures:
- Manual approval required for production deployments
- Secrets are scoped to the environment
- Deployment history is tracked

---

## Verifying Secrets

After adding secrets, you can verify they work by:

1. Running the workflow manually (workflow_dispatch)
2. Checking the logs for authentication errors
3. Verifying the Terraform/GKE operations succeed

---

## Security Best Practices

1. **Use least privilege**: Grant only necessary IAM roles
2. **Rotate keys regularly**: Regenerate service account keys periodically
3. **Use environments**: Use GitHub Environments for production
4. **Audit access**: Regularly review who has access to secrets
5. **Monitor usage**: Check GCP audit logs for service account usage

---

## Troubleshooting

### "Authentication failed"
- Verify `GCP_SA_KEY` is valid JSON
- Check service account has necessary permissions
- Ensure project ID is correct

### "Permission denied"
- Verify IAM roles are assigned correctly
- Check service account is not disabled
- Ensure project billing is enabled

### "Zone not available"
- Check H100 GPU availability in selected zone
- Verify quota limits
- Try a different zone

---

## Example Service Account Roles

For minimal permissions, use these roles instead of `roles/owner`:

```bash
# For VM deployment
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

# For GKE deployment
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"

# For Terraform state (if using GCS)
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Service account user (required)
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

