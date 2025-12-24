#!/bin/bash
# Deploy all Kubernetes manifests in the correct order

set -e

echo "🚀 Starting deployment of HostlyMA stack..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_wait() {
    echo -e "${YELLOW}[WAIT]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to k8s directory
cd "$(dirname "$0")"

# Step 1: Deploy PostgreSQL
print_step "Deploying PostgreSQL..."
kubectl apply -f postgres/
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s || {
    print_error "PostgreSQL failed to start"
    exit 1
}
echo -e "${GREEN}✓ PostgreSQL is ready${NC}"

# Step 2: Deploy Backend
print_step "Deploying Backend (hostly-web)..."
kubectl apply -f backend/
print_wait "Waiting for backend pods to be ready..."
kubectl wait --for=condition=ready pod -l app=hostly-web --timeout=300s || {
    print_error "Backend failed to start"
    exit 1
}
echo -e "${GREEN}✓ Backend is ready${NC}"

# Step 3: Run database migrations
print_step "Running database migrations..."
kubectl exec -it deployment/hostly-web -- php artisan migrate --force || {
    print_error "Migrations failed"
    exit 1
}
echo -e "${GREEN}✓ Migrations completed${NC}"

# Step 4: Deploy Frontend
print_step "Deploying Frontend (hostly-react-front)..."
kubectl apply -f frontend/
print_wait "Waiting for frontend pods to be ready..."
kubectl wait --for=condition=ready pod -l app=hostly-react-front --timeout=300s || {
    print_error "Frontend failed to start"
    exit 1
}
echo -e "${GREEN}✓ Frontend is ready${NC}"

# Step 5: Deploy Gateway
print_step "Deploying Gateway (gatewayms)..."
kubectl apply -f gateway/
print_wait "Waiting for gateway pods to be ready..."
kubectl wait --for=condition=ready pod -l app=gatewayms --timeout=300s || {
    print_error "Gateway failed to start"
    exit 1
}
echo -e "${GREEN}✓ Gateway is ready${NC}"

# Summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "📊 Status:"
kubectl get pods
echo ""
echo "🌐 Services:"
kubectl get svc
echo ""
echo "🔗 Ingress:"
kubectl get ingress
echo ""
echo "🧪 Test endpoints:"
echo "  - Frontend:  http://46.224.158.32/"
echo "  - API Health: http://46.224.158.32/api/health"
echo "  - Admin:     http://46.224.158.32/admin"
echo ""


