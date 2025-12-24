# Fix GitHub Container Registry (GHCR) Secret for Private Images

## Problem

You're getting `403 Forbidden` when pulling private images from `ghcr.io`. This means the `ghcr-secret` either:
- Doesn't exist
- Has incorrect credentials
- The GitHub PAT doesn't have the right permissions
- Is in the wrong namespace

## Solution

### Step 1: Create/Update GitHub Personal Access Token (PAT)

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name: `Kubernetes Image Pull`
4. Select scopes:
   - ✅ **`read:packages`** (REQUIRED - to pull container images)
   - ✅ **`write:packages`** (if you also want to push images)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again!)

### Step 2: Delete Old Secret (if exists)

```bash
kubectl delete secret ghcr-secret --ignore-not-found=true
```

### Step 3: Create New Secret

Replace the placeholders with your actual values:

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL \
  --namespace=default
```

**Example:**
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=hostlyma \
  --docker-password=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
  --docker-email=admin@hostlyma.com \
  --namespace=default
```

### Step 4: Verify Secret

```bash
# Check secret exists
kubectl get secret ghcr-secret

# Check secret details (will show base64 encoded values)
kubectl get secret ghcr-secret -o yaml

# Verify it's a docker-registry type
kubectl describe secret ghcr-secret
```

You should see:
- Type: `kubernetes.io/dockerconfigjson`
- Data: `.dockerconfigjson` (base64 encoded)

### Step 5: Test Image Pull

```bash
# Test pulling the image manually (if you have docker on the node)
docker login ghcr.io -u YOUR_GITHUB_USERNAME -p YOUR_GITHUB_PAT
docker pull ghcr.io/hostlyma/hostly-web:latest
```

### Step 6: Restart Deployments

After creating/updating the secret, restart your deployments:

```bash
# Restart backend
kubectl rollout restart deployment/hostly-web

# Restart gateway
kubectl rollout restart deployment/gatewayms

# Restart frontend (if deployed)
kubectl rollout restart deployment/hostly-react-front
```

### Step 7: Verify Pods Can Pull Images

```bash
# Watch pods restart
kubectl get pods -w

# Check if image pull succeeds
kubectl describe pod -l app=hostly-web | grep -A 5 "Events"
```

## Common Issues

### Issue 1: "403 Forbidden" persists

**Causes:**
- PAT doesn't have `read:packages` scope
- Wrong username
- Token expired or revoked
- Organization/package permissions

**Fix:**
1. Verify PAT has `read:packages` scope
2. Check if the package is in an organization - you may need organization-level permissions
3. Regenerate PAT with correct scopes

### Issue 2: Secret exists but pods still fail

**Causes:**
- Secret in wrong namespace
- Deployment in different namespace
- Secret name mismatch

**Fix:**
```bash
# Check which namespace deployments are in
kubectl get deployments --all-namespaces

# Check secret is in the same namespace
kubectl get secret ghcr-secret -n default

# If deployment is in different namespace, create secret there too:
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL \
  --namespace=YOUR_NAMESPACE
```

### Issue 3: Organization Packages

If your images are in an organization (`ghcr.io/hostlyma/*`), you need:

1. **Organization-level permissions:**
   - Go to organization settings → Packages
   - Ensure your user has access

2. **Service account (recommended for production):**
   - Create a GitHub App or use a service account
   - Use its credentials instead of personal PAT

## Alternative: Use Service Account (Production)

For production, consider using a GitHub App or service account instead of a personal PAT:

```bash
# Create secret from GitHub App token
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_APP_ID \
  --docker-password=YOUR_GITHUB_APP_TOKEN \
  --docker-email=YOUR_EMAIL
```

## Verify Everything Works

```bash
# 1. Check secret exists
kubectl get secret ghcr-secret

# 2. Check pods are running
kubectl get pods

# 3. Check no image pull errors
kubectl get events --sort-by='.lastTimestamp' | grep -i "pull\|image"

# 4. Describe a pod to see if it pulled successfully
kubectl describe pod -l app=hostly-web | grep -A 10 "Events"
```

## Quick Fix Script

```bash
#!/bin/bash
# Quick fix for GHCR secret

echo "Enter your GitHub username:"
read GITHUB_USERNAME

echo "Enter your GitHub PAT (with read:packages scope):"
read -s GITHUB_PAT

echo "Enter your email:"
read GITHUB_EMAIL

# Delete old secret
kubectl delete secret ghcr-secret --ignore-not-found=true

# Create new secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GITHUB_USERNAME" \
  --docker-password="$GITHUB_PAT" \
  --docker-email="$GITHUB_EMAIL" \
  --namespace=default

echo "✅ Secret created! Restarting deployments..."
kubectl rollout restart deployment/hostly-web
kubectl rollout restart deployment/gatewayms

echo "✅ Done! Check pods: kubectl get pods"
```

## Summary

1. ✅ Create GitHub PAT with `read:packages` scope
2. ✅ Delete old `ghcr-secret` if exists
3. ✅ Create new `ghcr-secret` with correct credentials
4. ✅ Restart deployments
5. ✅ Verify pods can pull images

After these steps, your private images should pull successfully!

