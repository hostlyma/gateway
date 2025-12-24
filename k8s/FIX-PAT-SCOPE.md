# Fix GitHub PAT - Add read:packages Scope

## Problem

Your token `k8s-image-pull` has repository permissions but is missing the **`read:packages`** scope needed to pull container images from GHCR.

## Solution

### Step 1: Update Your Token

1. Go to: https://github.com/settings/tokens
2. Find your token: **`k8s-image-pull`**
3. Click on it to edit
4. Scroll down to **"Select scopes"** section
5. Check the box for: ✅ **`read:packages`**
   - This allows reading packages from GitHub Container Registry
6. Scroll to bottom and click **"Update token"**

### Step 2: Update Kubernetes Secret

After updating the token, update your Kubernetes secret:

```bash
# Delete old secret
kubectl delete secret ghcr-secret

# Create new secret with updated token
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=elmahdibouaiti \
  --docker-password=YOUR_UPDATED_TOKEN \
  --docker-email=mahdi.bouaiti@hightech.edu \
  --namespace=default
```

**Note**: If you updated the token in GitHub, you need to copy the new token value (it might have changed) and use it in the command above.

### Step 3: Restart Deployments

```bash
# Restart backend
kubectl rollout restart deployment/hostly-web

# Restart gateway
kubectl rollout restart deployment/gatewayms

# Check pod status
kubectl get pods -l app=hostly-web
```

## Required Scopes for Container Images

For pulling private container images, your token needs:

- ✅ **`read:packages`** - Read packages from GitHub Container Registry (REQUIRED)
- ✅ `write:packages` - Write packages (optional, only if you push images)

## Organization Packages

Since your packages are in the `@hostlyma` organization, you might also need:

1. **Organization permissions** (if required by org settings):
   - Go to: https://github.com/orgs/hostlyma/settings/packages
   - Check if organization requires specific permissions

2. **Package access**:
   - Go to: https://github.com/orgs/hostlyma/packages/container/backend
   - Click "Package settings"
   - Under "Manage access", ensure your user has access

## Verify Token Works

Test the token manually:

```bash
# Login with your token
docker login ghcr.io -u elmahdibouaiti -p YOUR_TOKEN

# Try to pull the image
docker pull ghcr.io/hostlyma/backend:latest
```

If this works, the token is correct and the Kubernetes secret should work too.

## Quick Fix Script

```bash
#!/bin/bash
# Update GHCR secret with new token

echo "Enter your updated GitHub PAT (with read:packages scope):"
read -sp "Token: " NEW_TOKEN
echo ""

kubectl delete secret ghcr-secret --ignore-not-found=true

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=elmahdibouaiti \
  --docker-password="$NEW_TOKEN" \
  --docker-email=mahdi.bouaiti@hightech.edu \
  --namespace=default

echo "✅ Secret updated! Restarting deployments..."
kubectl rollout restart deployment/hostly-web
kubectl rollout restart deployment/gatewayms

echo "✅ Done! Check pods: kubectl get pods"
```

## Summary

1. ✅ Go to GitHub token settings
2. ✅ Add `read:packages` scope to your `k8s-image-pull` token
3. ✅ Update Kubernetes secret with the token
4. ✅ Restart deployments
5. ✅ Verify pods can pull images

After adding the `read:packages` scope, your 403 error should be resolved!

