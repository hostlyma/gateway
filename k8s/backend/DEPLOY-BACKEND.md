# Backend Deployment Guide

Step-by-step guide to deploy the Laravel backend (hostly-web) to Kubernetes.

## Prerequisites

✅ PostgreSQL is deployed and running
✅ PostgreSQL database is accessible
✅ Docker image is built and pushed to GitHub Container Registry

## Step 1: Update Backend Secret

The backend secret needs to match your PostgreSQL credentials and have a valid APP_KEY.

### 1.1 Generate Laravel APP_KEY

You can generate an APP_KEY in two ways:

**Option A: Generate locally (if you have Laravel installed):**
```bash
cd Hostly-web
php artisan key:generate --show
```

**Option B: Generate in a temporary container:**
```bash
docker run --rm -it php:8.2-cli php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;"
```

### 1.2 Update secret.yaml

Edit `gatewayms/k8s/backend/secret.yaml`:

```yaml
stringData:
  APP_KEY: "base64:YOUR_GENERATED_KEY_HERE"  # From step 1.1
  
  # Database credentials - MUST match postgres-secret
  DB_USERNAME: "hostly_user"  # Must match POSTGRES_USER
  DB_PASSWORD: "Diamantine@2"  # Must match POSTGRES_PASSWORD
```

**Important**: 
- `DB_USERNAME` must match `POSTGRES_USER` in postgres-secret.yaml
- `DB_PASSWORD` must match `POSTGRES_PASSWORD` in postgres-secret.yaml

## Step 2: Create Database (if needed)

The backend expects a database. You can either:

**Option A: Use existing 'postgres' database:**
- Update ConfigMap: `DB_DATABASE: "postgres"`

**Option B: Create 'laravel' database:**
```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Create database
kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "CREATE DATABASE laravel;"
```

## Step 3: Verify Image Pull Secret

Make sure the GitHub Container Registry secret exists:

```bash
kubectl get secret ghcr-secret
```

If it doesn't exist, create it:
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL
```

## Step 4: Deploy Backend

```bash
# Apply all backend resources
kubectl apply -f gatewayms/k8s/backend/

# Wait for deployment to be ready
kubectl wait --for=condition=available deployment/hostly-web --timeout=300s

# Check pod status
kubectl get pods -l app=hostly-web
```

## Step 5: Run Migrations

After the backend is running, run Laravel migrations:

```bash
# Run migrations
kubectl exec -it deployment/hostly-web -- php artisan migrate --force

# Or if you need to specify database
kubectl exec -it deployment/hostly-web -- php artisan migrate --database=pgsql --force
```

## Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -l app=hostly-web

# Check service
kubectl get svc hostly-web-service

# Check logs
kubectl logs -f deployment/hostly-web

# Test health endpoint (from inside cluster)
kubectl run test-backend --rm -i --restart=Never --image=curlimages/curl -- curl http://hostly-web-service/api/health
```

## Troubleshooting

### Pod fails to start

```bash
# Check pod status
kubectl describe pod -l app=hostly-web

# Check logs
kubectl logs -l app=hostly-web

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Image pull errors

```bash
# Verify secret exists
kubectl get secret ghcr-secret

# Check if image exists
docker pull ghcr.io/hostlyma/hostly-web:latest
```

### Database connection errors

```bash
# Test database connection from backend pod
kubectl exec -it deployment/hostly-web -- php artisan tinker
# Then in tinker: DB::connection()->getPdo();

# Or test directly
kubectl exec -it deployment/hostly-web -- php -r "echo getenv('DB_HOST') . PHP_EOL;"
```

### Migration errors

```bash
# Check database exists
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "\l"

# Run migrations with verbose output
kubectl exec -it deployment/hostly-web -- php artisan migrate --force -v
```

## Next Steps

After backend is deployed:

1. ✅ Deploy frontend
2. ✅ Deploy gateway
3. ✅ Configure ingress/routing
4. ✅ Test full stack

## Configuration Summary

- **Service**: `hostly-web-service:80` (ClusterIP - internal)
- **Health Check**: `/api/health`
- **Database**: PostgreSQL via `postgres-service:5432`
- **Replicas**: 2 (for high availability)

