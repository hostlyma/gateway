# Troubleshooting 403 Forbidden on GHCR

Your secret exists and looks correct. The 403 error is likely due to one of these issues:

## Issue 1: PAT Missing `read:packages` Scope

Your GitHub PAT needs the `read:packages` scope to pull private images.

### Check Current PAT Scopes

1. Go to: https://github.com/settings/tokens
2. Find your token (starts with `github_pat_11A3TPECI0...`)
3. Check if it has **`read:packages`** scope

### If Missing, Create New PAT

1. Go to: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name: `Kubernetes Image Pull`
4. Select scopes:
   - ✅ **`read:packages`** (REQUIRED)
   - ✅ `write:packages` (optional, if you push images)
5. Generate and copy the token
6. Update the secret:

```bash
kubectl delete secret ghcr-secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=elmahdibouaiti \
  --docker-password=YOUR_NEW_PAT \
  --docker-email=mahdi.bouaiti@hightech.edu \
  --namespace=default
```

## Issue 2: Package Doesn't Exist

Verify the package exists:

1. Go to: https://github.com/hostlyma/backend/pkgs/container/backend
2. Or check: https://github.com/orgs/hostlyma/packages

If it doesn't exist, you need to build and push it first:

```bash
# Build and push the image
docker login ghcr.io -u elmahdibouaiti -p YOUR_PAT
cd Hostly-web  # or wherever your backend code is
docker build -t ghcr.io/hostlyma/backend:latest .
docker push ghcr.io/hostlyma/backend:latest
```

## Issue 3: Organization Permissions

If the package is in the `hostlyma` organization:

1. Go to: https://github.com/orgs/hostlyma/settings/packages
2. Check package visibility settings
3. Ensure your user (`elmahdibouaiti`) has access
4. Check organization member permissions

### Grant Access to Package

1. Go to the package: https://github.com/orgs/hostlyma/packages/container/backend
2. Click "Package settings"
3. Under "Manage access", add your user or a team
4. Grant "Read" permission at minimum

## Issue 4: Package Visibility

Check if the package is:
- **Public**: Anyone can pull (no auth needed)
- **Private**: Requires authentication with proper permissions

If you want to keep it private, ensure:
- PAT has `read:packages` scope
- User has access to the package
- Organization permissions are correct

## Quick Test

Test if you can pull the image manually:

```bash
# On your local machine or k8s-node
docker login ghcr.io -u elmahdibouaiti -p YOUR_PAT
docker pull ghcr.io/hostlyma/backend:latest
```

If this works locally but fails in Kubernetes:
- Secret might be in wrong namespace
- Secret format might be incorrect
- Pod might be in different namespace

## Verify Secret in Kubernetes

```bash
# Check secret exists
kubectl get secret ghcr-secret

# Check secret is in correct namespace
kubectl get secret ghcr-secret -n default

# Decode and verify (username should match)
kubectl get secret ghcr-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq '.auths."ghcr.io".username'
```

## Restart After Fixing

After updating the secret or permissions:

```bash
# Delete pods to force re-pull
kubectl delete pods -l app=hostly-web

# Or restart deployment
kubectl rollout restart deployment/hostly-web
```

## Most Likely Solution

Based on your setup, the most likely issue is:

1. **PAT missing `read:packages` scope** - Create new PAT with this scope
2. **Package doesn't exist yet** - Build and push the image first
3. **Organization permissions** - Grant access to the package

Try these in order and check pod events:

```bash
kubectl describe pod -l app=hostly-web | grep -A 10 "Events"
```

This will show the exact error message.

