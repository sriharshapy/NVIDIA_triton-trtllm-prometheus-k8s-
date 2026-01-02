# GitHub Actions Setup Guide

This guide will help you set up GitHub Actions for automated GCP infrastructure deployment.

## Step 1: Create GCP Service Account

```bash
# Set your project ID
export PROJECT_ID="your-project-id"

# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=$PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --project=$PROJECT_ID
```

## Step 2: Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** for each secret:

### Required Secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `GCP_SA_KEY` | Contents of `github-actions-key.json` | Service account JSON key |
| `GCP_PROJECT_ID` | Your GCP project ID | Project identifier |

### Optional Secrets (with defaults):

| Secret Name | Default Value | Description |
|------------|---------------|-------------|
| `GCP_REGION` | `us-central1` | GCP region |
| `GCP_ZONE` | `us-central1-a` | GCP zone |
| `GKE_CLUSTER_NAME` | `trt-llm-cluster` | GKE cluster name |

## Step 3: Set Up Environment Protection (Recommended)

For production deployments:

1. Go to **Settings** → **Environments**
2. Click **"New environment"**
3. Name it `production`
4. Configure:
   - **Required reviewers**: Add yourself/team
   - **Deployment branches**: `main` only
   - Add the same secrets to the environment

## Step 4: Test the Workflow

1. Go to **Actions** tab in your repository
2. Select **"Deploy GCP Infrastructure"** workflow
3. Click **"Run workflow"**
4. Choose:
   - **Deployment type**: `gke` or `vm`
   - **Action**: `plan` (to test first)
5. Click **"Run workflow"**

## Available Workflows

### 1. Deploy GCP Infrastructure (`deploy-infra.yml`)

**Triggers**:
- Manual (workflow_dispatch)
- Push to `main` (plan only)
- Pull requests (plan only)

**Actions**:
- `plan` - Show what will be created (safe, no changes)
- `apply` - Create infrastructure
- `destroy` - Remove infrastructure

**Usage**:
```yaml
# Manual trigger
Actions → Deploy GCP Infrastructure → Run workflow
  - Deployment type: gke
  - Action: apply
```

### 2. Deploy to Kubernetes (`deploy-k8s.yml`)

**Triggers**:
- Manual (workflow_dispatch)
- Push to `main` (if k8s files change)

**Actions**:
- `deploy` - Deploy Triton to Kubernetes
- `undeploy` - Remove Triton from Kubernetes

**Usage**:
```yaml
# Manual trigger
Actions → Deploy to Kubernetes → Run workflow
  - Action: deploy
```

### 3. CI - Lint and Validate (`ci.yml`)

**Triggers**:
- Pull requests
- Push to `main`

**Validates**:
- Terraform syntax and format
- Kubernetes manifest validity
- Python code linting
- Shell script validation

## Workflow Examples

### Example 1: Deploy GKE Cluster

1. Go to Actions → Deploy GCP Infrastructure
2. Run workflow with:
   - Deployment type: `gke`
   - Action: `plan` (first time)
3. Review the plan output
4. Run again with:
   - Deployment type: `gke`
   - Action: `apply`
5. Wait for completion (~10-15 minutes)

### Example 2: Deploy Triton to Kubernetes

1. Ensure GKE cluster exists (from Example 1)
2. Go to Actions → Deploy to Kubernetes
3. Run workflow with:
   - Action: `deploy`
4. Wait for deployment (~5 minutes)
5. Get external IP from workflow summary

### Example 3: Destroy Infrastructure

1. Go to Actions → Deploy GCP Infrastructure
2. Run workflow with:
   - Deployment type: `gke` (or `vm`)
   - Action: `destroy`
3. Confirm in workflow logs

## Monitoring Workflows

### View Logs

1. Go to **Actions** tab
2. Click on a workflow run
3. Click on a job to see detailed logs
4. Each step includes timestamps and logging

### Workflow Status Badge

Add to your README.md:

```markdown
![Infrastructure](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Deploy%20GCP%20Infrastructure/badge.svg)
```

## Troubleshooting

### "Authentication failed"
- Verify `GCP_SA_KEY` secret is correct
- Check service account is not disabled
- Ensure JSON key is complete (no truncation)

### "Permission denied"
- Verify IAM roles are assigned
- Check service account has necessary permissions
- Ensure project billing is enabled

### "Zone not available"
- Check H100 GPU availability
- Verify quota limits
- Try different zone

### "Cluster not found"
- Ensure cluster exists before deploying K8s
- Check `GKE_CLUSTER_NAME` secret matches actual cluster name
- Verify zone matches cluster location

## Security Notes

1. **Never commit secrets** to repository
2. **Use environment protection** for production
3. **Rotate service account keys** regularly
4. **Review workflow logs** for sensitive data
5. **Use least privilege** IAM roles

## Next Steps

After infrastructure is deployed:

1. Upload model files (see main README.md)
2. Test inference endpoint
3. Set up monitoring and alerts
4. Configure auto-scaling if needed

## Support

For issues:
1. Check workflow logs
2. Review GitHub Secrets configuration
3. Verify GCP permissions
4. Check Terraform state (if using remote state)

