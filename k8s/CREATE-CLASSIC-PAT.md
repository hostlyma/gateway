# Create Classic GitHub PAT with read:packages Scope

## Problem

Fine-grained tokens don't have the `read:packages` scope. You need a **Classic Token** instead.

## Solution: Create a Classic Token

### Step 1: Go to Classic Tokens

1. Go to: https://github.com/settings/tokens
2. You'll see two options:
   - **Personal access tokens** (Classic) ← Use this one!
   - **Fine-grained tokens** (Beta) ← Not this one

3. Click on **"Personal access tokens"** → **"Tokens (classic)"**

### Step 2: Generate New Classic Token

1. Click **"Generate new token"** → **"Generate new token (classic)"**
2. Give it a name: `k8s-image-pull-classic`
3. Set expiration (e.g., 1 year or no expiration)
4. **Select scopes** - Check these boxes:
   - ✅ **`read:packages`** ← This is what you need!
   - ✅ `write:packages` (optional, if you also push images)
5. Click **"Generate token"** at the bottom
6. **Copy the token immediately** - you won't see it again!

### Step 3: Update Kubernetes Secret

Use the new classic token:

```bash
# Delete old secret
kubectl delete secret ghcr-secret

# Create new secret with classic token
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=elmahdibouaiti \
  --docker-password=YOUR_CLASSIC_TOKEN_HERE \
  --docker-email=mahdi.bouaiti@hightech.edu \
  --namespace=default
```

### Step 4: Restart Deployments

```bash
kubectl rollout restart deployment/hostly-web
kubectl rollout restart deployment/gatewayms

# Check status
kubectl get pods -l app=hostly-web
```

## Why Classic Token?

- **Fine-grained tokens**: Newer, more secure, but don't support `read:packages` yet
- **Classic tokens**: Older format, but have full access to all scopes including `read:packages`

For container registry access, you **must** use a classic token until GitHub adds package permissions to fine-grained tokens.

## Visual Guide

```
GitHub Settings → Developer settings → Personal access tokens
├── Personal access tokens (Classic) ← Click here!
│   └── Generate new token (classic)
│       └── Select scopes:
│           ✅ read:packages
│           ✅ write:packages (optional)
│
└── Fine-grained tokens (Beta) ← Don't use this for packages
```

## Alternative: Use GitHub App

If you prefer not to use classic tokens, you can create a GitHub App:

1. Go to: https://github.com/settings/apps
2. Click "New GitHub App"
3. Set permissions:
   - Contents: Read
   - Metadata: Read
   - Packages: Read
4. Generate and use the app's token

But classic token is simpler for this use case.

## Summary

1. ✅ Go to **Tokens (classic)** (not fine-grained)
2. ✅ Generate new classic token
3. ✅ Select **`read:packages`** scope
4. ✅ Copy the token
5. ✅ Update Kubernetes secret
6. ✅ Restart deployments

The classic token will have the `read:packages` scope you need!

