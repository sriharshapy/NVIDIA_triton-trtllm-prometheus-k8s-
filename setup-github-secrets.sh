#!/bin/bash
# Setup script for GitHub Actions secrets
# Project: trt-deployment (279105096022)

set -e

PROJECT_ID="trt-deployment"
PROJECT_NUMBER="279105096022"
SERVICE_ACCOUNT_NAME="github-actions-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="github-actions-key.json"

echo "=========================================="
echo "GitHub Actions Secrets Setup"
echo "=========================================="
echo "Project ID: $PROJECT_ID"
echo "Project Number: $PROJECT_NUMBER"
echo "=========================================="
echo ""

# Step 1: Create service account
echo "[1/4] Creating service account..."
if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Service account already exists: $SERVICE_ACCOUNT_EMAIL"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="GitHub Actions Service Account" \
        --project=$PROJECT_ID
    echo "✓ Service account created: $SERVICE_ACCOUNT_EMAIL"
fi
echo ""

# Step 2: Grant permissions
echo "[2/4] Granting permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/owner" \
    --condition=None
echo "✓ Permissions granted (roles/owner)"
echo ""

# Step 3: Create key
echo "[3/4] Creating service account key..."
if [ -f "$KEY_FILE" ]; then
    read -p "Key file exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping key creation. Using existing file."
    else
        gcloud iam service-accounts keys create $KEY_FILE \
            --iam-account=$SERVICE_ACCOUNT_EMAIL \
            --project=$PROJECT_ID
        echo "✓ Key created: $KEY_FILE"
    fi
else
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_EMAIL \
        --project=$PROJECT_ID
    echo "✓ Key created: $KEY_FILE"
fi
echo ""

# Step 4: Display secrets to add
echo "[4/4] GitHub Secrets to Add"
echo "=========================================="
echo ""
echo "Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
echo ""
echo "Add these secrets:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Secret Name: GCP_SA_KEY"
echo "   Value: (Full contents of $KEY_FILE)"
echo "   Command to get value:"
echo "   cat $KEY_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Secret Name: GCP_PROJECT_ID"
echo "   Value: $PROJECT_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Secret Name: GCP_REGION (Optional)"
echo "   Value: us-central1"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Secret Name: GCP_ZONE (Optional)"
echo "   Value: us-central1-a"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Secret Name: GKE_CLUSTER_NAME (Optional)"
echo "   Value: trt-llm-cluster"
echo ""
echo "=========================================="
echo "Quick Copy Commands:"
echo "=========================================="
echo ""
echo "# View the key file content:"
echo "cat $KEY_FILE"
echo ""
echo "# Copy key to clipboard (macOS):"
echo "cat $KEY_FILE | pbcopy"
echo ""
echo "# Copy key to clipboard (Linux):"
echo "cat $KEY_FILE | xclip -selection clipboard"
echo ""
echo "=========================================="
echo "Setup completed!"
echo "=========================================="

