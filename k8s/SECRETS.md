# Kubernetes Secrets Guide

## Required Secrets

This deployment requires the following secrets to be created in Kubernetes:

### 1. Image Pull Secret (ghcr-secret)

**Purpose**: Allows Kubernetes to pull Docker images from GitHub Container Registry (ghcr.io)

**Type**: `docker-registry`

**Already Created**: ✅ You mentioned you've already created this secret named `ghcr-secret`

**Verify it exists:**
```bash
kubectl get secret ghcr-secret
kubectl describe secret ghcr-secret
```

**If you need to recreate it:**
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL \
  --namespace=default
```

**Note**: All deployments reference this secret via `imagePullSecrets` in their pod specs.

### 2. Backend Application Secret (hostly-web-secret)

**Purpose**: Stores Laravel application key and database credentials

**Location**: `backend/secret.yaml`

**Update before deployment:**
```yaml
stringData:
  APP_KEY: "base64:YOUR_GENERATED_KEY"  # Generate with: php artisan key:generate
  DB_USERNAME: "laravel"
  DB_PASSWORD: "YOUR_SECURE_PASSWORD"
```

**Apply after updating:**
```bash
kubectl apply -f backend/secret.yaml
```

### 3. PostgreSQL Secret (postgres-secret)

**Purpose**: Stores PostgreSQL database credentials

**Location**: `postgres/postgres-secret.yaml`

**Update before deployment:**
```yaml
stringData:
  POSTGRES_DB: "laravel"
  POSTGRES_USER: "laravel"
  POSTGRES_PASSWORD: "YOUR_SECURE_PASSWORD"  # Must match backend DB_PASSWORD
```

**Apply after updating:**
```bash
kubectl apply -f postgres/postgres-secret.yaml
```

## Secret Management Best Practices

1. **Never commit secrets** - Use `secret.yaml` files but update values before applying
2. **Use strong passwords** - Generate secure passwords for production
3. **Match credentials** - Ensure `DB_PASSWORD` in backend matches `POSTGRES_PASSWORD` in postgres
4. **Rotate secrets** - Regularly update secrets for security
5. **Verify secrets** - Always verify secrets exist before deploying:
   ```bash
   kubectl get secrets
   ```

## Verification Commands

```bash
# List all secrets
kubectl get secrets

# Verify image pull secret
kubectl get secret ghcr-secret -o yaml

# Verify backend secret (base64 encoded)
kubectl get secret hostly-web-secret -o yaml

# Verify postgres secret (base64 encoded)
kubectl get secret postgres-secret -o yaml

# Decode a secret value (example)
kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

## Troubleshooting

### Image Pull Errors

If you see `ImagePullBackOff` or `ErrImagePull`:

1. Verify `ghcr-secret` exists:
   ```bash
   kubectl get secret ghcr-secret
   ```

2. Check secret is in correct namespace (should be `default`):
   ```bash
   kubectl get secret ghcr-secret -n default
   ```

3. Verify GitHub PAT token is valid and has `read:packages` permission

4. Check pod events:
   ```bash
   kubectl describe pod <pod-name>
   ```

### Database Connection Errors

If backend can't connect to database:

1. Verify both secrets exist:
   ```bash
   kubectl get secret hostly-web-secret
   kubectl get secret postgres-secret
   ```

2. Verify passwords match:
   ```bash
   # Decode backend password
   kubectl get secret hostly-web-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
   
   # Decode postgres password
   kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
   ```

3. Ensure postgres pod is running:
   ```bash
   kubectl get pods -l app=postgres
   ```

---

**Last Updated**: 2024-12-24

