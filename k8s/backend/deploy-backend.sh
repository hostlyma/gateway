#!/bin/bash
# Backend deployment script

set -e

echo "=== Backend Deployment Script ==="
echo ""

# Step 1: Check prerequisites
echo "Step 1: Checking prerequisites..."
echo ""

echo "Checking PostgreSQL..."
kubectl get pods -l app=postgres >/dev/null 2>&1 || {
    echo "❌ Error: PostgreSQL pod not found. Deploy PostgreSQL first!"
    exit 1
}
echo "✅ PostgreSQL is running"
echo ""

echo "Checking ghcr-secret..."
kubectl get secret ghcr-secret >/dev/null 2>&1 || {
    echo "⚠️  Warning: ghcr-secret not found. You may need to create it:"
    echo "   kubectl create secret docker-registry ghcr-secret \\"
    echo "     --docker-server=ghcr.io \\"
    echo "     --docker-username=YOUR_GITHUB_USERNAME \\"
    echo "     --docker-password=YOUR_GITHUB_PAT \\"
    echo "     --docker-email=YOUR_EMAIL"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
}
echo "✅ ghcr-secret exists"
echo ""

# Step 2: Check if APP_KEY is set
echo "Step 2: Checking APP_KEY..."
APP_KEY=$(kubectl get secret hostly-web-secret -o jsonpath='{.data.APP_KEY}' 2>/dev/null | base64 -d 2>/dev/null || echo "")

if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:CHANGE_THIS_TO_YOUR_APP_KEY" ]; then
    echo "⚠️  APP_KEY needs to be set!"
    echo ""
    echo "Generating APP_KEY..."
    NEW_KEY=$(docker run --rm php:8.2-cli php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;" 2>/dev/null || echo "")
    
    if [ -z "$NEW_KEY" ]; then
        echo "❌ Could not generate APP_KEY automatically"
        echo "Please edit gatewayms/k8s/backend/secret.yaml and set APP_KEY manually"
        exit 1
    fi
    
    echo "Generated APP_KEY: $NEW_KEY"
    echo ""
    read -p "Update secret.yaml with this key? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Update secret.yaml (this is a simple approach - in production, use kubectl patch)
        echo "Please update secret.yaml manually with: APP_KEY: \"$NEW_KEY\""
        echo "Then run: kubectl apply -f gatewayms/k8s/backend/secret.yaml"
        read -p "Press Enter after updating secret.yaml..."
    fi
else
    echo "✅ APP_KEY is set"
fi
echo ""

# Step 3: Create database if needed
echo "Step 3: Checking database..."
DB_NAME=$(kubectl get configmap hostly-web-config -o jsonpath='{.data.DB_DATABASE}' 2>/dev/null || echo "laravel")
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

DB_EXISTS=$(kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || echo "0")

if [ "$DB_EXISTS" != "1" ]; then
    echo "Database '$DB_NAME' does not exist. Creating..."
    kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "CREATE DATABASE $DB_NAME;" || {
        echo "❌ Failed to create database"
        exit 1
    }
    echo "✅ Database '$DB_NAME' created"
else
    echo "✅ Database '$DB_NAME' exists"
fi
echo ""

# Step 4: Deploy backend
echo "Step 4: Deploying backend..."
kubectl apply -f gatewayms/k8s/backend/
echo ""

# Step 5: Wait for deployment
echo "Step 5: Waiting for backend to be ready..."
kubectl wait --for=condition=available deployment/hostly-web --timeout=300s || {
    echo "❌ Deployment failed or timed out"
    echo "Check logs: kubectl logs -l app=hostly-web"
    exit 1
}
echo "✅ Backend is ready"
echo ""

# Step 6: Run migrations
echo "Step 6: Running migrations..."
kubectl exec -it deployment/hostly-web -- php artisan migrate --force || {
    echo "⚠️  Migration failed. You may need to run manually:"
    echo "   kubectl exec -it deployment/hostly-web -- php artisan migrate --force"
}
echo ""

# Step 7: Verify
echo "Step 7: Verifying deployment..."
echo ""
echo "Pod status:"
kubectl get pods -l app=hostly-web
echo ""
echo "Service:"
kubectl get svc hostly-web-service
echo ""
echo "Testing health endpoint..."
kubectl run test-backend --rm -i --restart=Never --image=curlimages/curl -- curl -s http://hostly-web-service/api/health || echo "Health check failed"
echo ""

echo "=== Deployment Complete ==="
echo ""
echo "Backend is available at: hostly-web-service:80 (internal)"
echo "Health check: http://hostly-web-service/api/health"

