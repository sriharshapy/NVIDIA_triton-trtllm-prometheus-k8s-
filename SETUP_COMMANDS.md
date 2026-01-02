# Setup Commands for trt-deployment Project

## Project Information

- **Project ID**: `trt-deployment`
- **Project Number**: `279105096022`
- **Service Account**: `github-actions-sa@trt-deployment.iam.gserviceaccount.com`

---

## macOS Setup

### Prerequisites

```bash
# Install Google Cloud SDK (if not installed)
# Download from: https://cloud.google.com/sdk/docs/install
# Or use Homebrew:
brew install --cask google-cloud-sdk

# Authenticate
gcloud auth login
gcloud config set project trt-deployment
```

### Step 1: Create Service Account

> **⚠️ Note**: If you get an error saying "Service account already exists", **skip this step** and proceed to Step 2. This is normal if you've run the setup before.

```bash
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=trt-deployment
```

**If service account already exists**, verify it and proceed to Step 2:
```bash
gcloud iam service-accounts describe \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

### Step 2: Grant Permissions

```bash
gcloud projects add-iam-policy-binding trt-deployment \
    --member="serviceAccount:github-actions-sa@trt-deployment.iam.gserviceaccount.com" \
    --role="roles/owner"
```

### Step 3: Create Key File

```bash
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

### Step 4: Copy Key to Clipboard

```bash
# View the key
cat github-actions-key.json

# Copy to clipboard (macOS)
cat github-actions-key.json | pbcopy

# Verify it's copied
echo "Key copied to clipboard! ✓"
```

### Step 5: Add to GitHub Secrets

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add secrets (see GitHub Secrets section below)

### Verify Setup (macOS)

```bash
# Check service account
gcloud iam service-accounts describe \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment

# List keys
gcloud iam service-accounts keys list \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

### Cleanup Key File (macOS)

```bash
# Securely delete the key file after adding to GitHub
rm github-actions-key.json
# Or use secure delete:
srm github-actions-key.json
```

---

## Windows PowerShell Setup

### Prerequisites

```powershell
# Install Google Cloud SDK (if not installed)
# Download from: https://cloud.google.com/sdk/docs/install
# Or use Chocolatey:
choco install gcloudsdk

# Authenticate
gcloud auth login
gcloud config set project trt-deployment
```

### Step 1: Create Service Account

> **⚠️ Note**: If you get an error saying "Service account already exists", **skip this step** and proceed to Step 2. This is normal if you've run the setup before.

```powershell
gcloud iam service-accounts create github-actions-sa `
    --display-name="GitHub Actions Service Account" `
    --project=trt-deployment
```

**If service account already exists**, verify it and proceed to Step 2:
```powershell
gcloud iam service-accounts describe `
    github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

### Step 2: Grant Permissions

```powershell
gcloud projects add-iam-policy-binding trt-deployment `
    --member="serviceAccount:github-actions-sa@trt-deployment.iam.gserviceaccount.com" `
    --role="roles/owner"
```

### Step 3: Create Key File

```powershell
gcloud iam service-accounts keys create github-actions-key.json `
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

### Step 4: Copy Key to Clipboard

```powershell
# View the key
Get-Content github-actions-key.json

# Copy to clipboard (PowerShell)
Get-Content github-actions-key.json | Set-Clipboard

# Verify it's copied
Write-Host "Key copied to clipboard! ✓" -ForegroundColor Green
```

### Alternative: View in Notepad

```powershell
# Open in Notepad to copy manually
notepad github-actions-key.json
```

### Step 5: Add to GitHub Secrets

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add secrets (see GitHub Secrets section below)

### Verify Setup (PowerShell)

```powershell
# Check service account
gcloud iam service-accounts describe `
    github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment

# List keys
gcloud iam service-accounts keys list `
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

### Cleanup Key File (PowerShell)

```powershell
# Securely delete the key file after adding to GitHub
Remove-Item github-actions-key.json -Force

# Or use secure delete (if available)
cipher /w:github-actions-key.json
Remove-Item github-actions-key.json -Force
```

---

## Linux Setup

### Prerequisites

```bash
# Install Google Cloud SDK (if not installed)
# Download from: https://cloud.google.com/sdk/docs/install
# Or use package manager:

# Debian/Ubuntu
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# RHEL/CentOS
sudo yum install -y google-cloud-sdk

# Authenticate
gcloud auth login
gcloud config set project trt-deployment
```

### Step 1: Create Service Account

> **⚠️ Note**: If you get an error saying "Service account already exists", **skip this step** and proceed to Step 2. This is normal if you've run the setup before.

```bash
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=trt-deployment
```

**If service account already exists**, verify it and proceed to Step 2:
```bash
gcloud iam service-accounts describe \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

### Step 2: Grant Permissions

```bash
gcloud projects add-iam-policy-binding trt-deployment \
    --member="serviceAccount:github-actions-sa@trt-deployment.iam.gserviceaccount.com" \
    --role="roles/owner"
```

### Step 3: Create Key File

```bash
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

### Step 4: Copy Key to Clipboard

```bash
# View the key
cat github-actions-key.json

# Copy to clipboard (Linux - requires xclip)
# Install xclip if needed: sudo apt-get install xclip
cat github-actions-key.json | xclip -selection clipboard

# Or for Wayland (GNOME)
cat github-actions-key.json | wl-copy

# Verify it's copied
echo "Key copied to clipboard! ✓"
```

### Alternative: View in Editor

```bash
# Open in nano/vim to copy manually
nano github-actions-key.json
# Or
vim github-actions-key.json
```

### Step 5: Add to GitHub Secrets

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add secrets (see GitHub Secrets section below)

### Verify Setup (Linux)

```bash
# Check service account
gcloud iam service-accounts describe \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment

# List keys
gcloud iam service-accounts keys list \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

### Cleanup Key File (Linux)

```bash
# Securely delete the key file after adding to GitHub
shred -u github-actions-key.json

# Or if shred not available
rm -f github-actions-key.json
```

---

## GitHub Secrets to Add

Go to: **Settings → Secrets and variables → Actions → New repository secret**

### Required Secrets:

1. **GCP_SA_KEY**
   - **Value**: Full contents of `github-actions-key.json`
   - **How to get**:
     - **macOS**: `cat github-actions-key.json | pbcopy`
     - **PowerShell**: `Get-Content github-actions-key.json | Set-Clipboard`
     - **Linux**: `cat github-actions-key.json | xclip -selection clipboard`
   - **Paste**: The entire JSON content (starts with `{` and ends with `}`)

2. **GCP_PROJECT_ID**
   - **Value**: `trt-deployment`
   - **Type**: Plain text

### Optional Secrets (with defaults):

3. **GCP_REGION**
   - **Value**: `us-central1`
   - **Default**: `us-central1` (if not set)

4. **GCP_ZONE**
   - **Value**: `us-central1-a`
   - **Default**: `us-central1-a` (if not set)

5. **GKE_CLUSTER_NAME**
   - **Value**: `trt-llm-cluster`
   - **Default**: `trt-llm-cluster` (if not set)

---

## Automated Setup Script

### macOS / Linux

```bash
# Make script executable
chmod +x setup-github-secrets.sh

# Run the script
./setup-github-secrets.sh
```

### Windows PowerShell

```powershell
# Run the script (if using Git Bash or WSL)
bash setup-github-secrets.sh

# Or run commands manually (see PowerShell section above)
```

---

## Test the Workflow

After adding secrets:

1. Go to **Actions** tab in GitHub
2. Select **"Deploy GCP Infrastructure"**
3. Click **"Run workflow"**
4. Choose:
   - **Deployment type**: `gke`
   - **Action**: `plan` (to test first)
5. Click **"Run workflow"**

---

## Verification Commands

### Check Service Account Exists

**macOS/Linux:**
```bash
gcloud iam service-accounts describe \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

**PowerShell:**
```powershell
gcloud iam service-accounts describe `
    github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

### List Service Account Keys

**macOS/Linux:**
```bash
gcloud iam service-accounts keys list \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

**PowerShell:**
```powershell
gcloud iam service-accounts keys list `
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

### Verify Permissions

**macOS/Linux:**
```bash
gcloud projects get-iam-policy trt-deployment \
    --flatten="bindings[].members" \
    --filter="bindings.members:github-actions-sa@trt-deployment.iam.gserviceaccount.com"
```

**PowerShell:**
```powershell
gcloud projects get-iam-policy trt-deployment `
    --flatten="bindings[].members" `
    --filter="bindings.members:github-actions-sa@trt-deployment.iam.gserviceaccount.com"
```

---

## Security Notes

⚠️ **Important**:
- The key file (`github-actions-key.json`) contains sensitive credentials
- **DO NOT** commit it to git
- Add it to `.gitignore` (already included)
- **Delete the file after adding to GitHub secrets**
- Rotate keys periodically (every 90 days recommended)

### Secure Deletion

**macOS:**
```bash
srm github-actions-key.json  # Secure delete
```

**PowerShell:**
```powershell
cipher /w:github-actions-key.json  # Overwrite with zeros
Remove-Item github-actions-key.json -Force
```

**Linux:**
```bash
shred -u github-actions-key.json  # Secure delete
```

---

## Cleanup (if needed)

### Delete Service Account Key

**macOS/Linux:**
```bash
# First, list keys to get KEY_ID
gcloud iam service-accounts keys list \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment

# Then delete (replace KEY_ID)
gcloud iam service-accounts keys delete KEY_ID \
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

**PowerShell:**
```powershell
# First, list keys to get KEY_ID
gcloud iam service-accounts keys list `
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment

# Then delete (replace KEY_ID)
gcloud iam service-accounts keys delete KEY_ID `
    --iam-account=github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

### Delete Service Account

**macOS/Linux:**
```bash
gcloud iam service-accounts delete \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment
```

**PowerShell:**
```powershell
gcloud iam service-accounts delete `
    github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment
```

---

## Troubleshooting

### "Permission denied" Error

**Solution:**
```bash
# Verify you're authenticated
gcloud auth list

# Verify project is set
gcloud config get-value project

# Re-authenticate if needed
gcloud auth login
```

### "Service account already exists"

**Solution:**
This is **normal** if you've run the setup before. Simply **skip Step 1** and proceed to Step 2 (Grant Permissions). The service account is already created and ready to use.

**macOS/Linux:**
```bash
# Verify it exists (optional)
gcloud iam service-accounts describe \
    github-actions-sa@trt-deployment.iam.gserviceaccount.com \
    --project=trt-deployment

# If exists, skip creation and proceed to Step 2
```

**PowerShell:**
```powershell
# Verify it exists (optional)
gcloud iam service-accounts describe `
    github-actions-sa@trt-deployment.iam.gserviceaccount.com `
    --project=trt-deployment

# If exists, skip creation and proceed to Step 2
```

### "Key file already exists"

**Solution:**
```bash
# Backup existing key
mv github-actions-key.json github-actions-key.json.backup

# Create new key
# (use commands from Step 3)
```

### Clipboard Not Working

**macOS:**
- Use `pbcopy` (should work by default)
- Alternative: Open file in TextEdit: `open -a TextEdit github-actions-key.json`

**PowerShell:**
- Use `Set-Clipboard` (PowerShell 5.0+)
- Alternative: Open in Notepad: `notepad github-actions-key.json`

**Linux:**
- Install xclip: `sudo apt-get install xclip`
- Or use Wayland: `sudo apt-get install wl-clipboard`
- Alternative: View in editor: `nano github-actions-key.json`

---

## Quick Reference

| Platform | Copy Command | View Command |
|----------|-------------|--------------|
| **macOS** | `cat github-actions-key.json \| pbcopy` | `cat github-actions-key.json` |
| **PowerShell** | `Get-Content github-actions-key.json \| Set-Clipboard` | `Get-Content github-actions-key.json` |
| **Linux** | `cat github-actions-key.json \| xclip -sel clip` | `cat github-actions-key.json` |

---

## Next Steps

After completing setup:

1. ✅ Secrets added to GitHub
2. ✅ Test workflow with `plan` action
3. ✅ Deploy infrastructure with `apply` action
4. ✅ Deploy Triton to Kubernetes
5. ✅ Upload model files
6. ✅ Test inference endpoint

For detailed workflow instructions, see [`.github/SETUP.md`](.github/SETUP.md)
