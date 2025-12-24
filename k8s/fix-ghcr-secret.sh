#!/bin/bash
# Quick fix script for GHCR secret

set -e

echo "=== Fix GitHub Container Registry Secret ==="
echo ""

# Check if secret exists
if kubectl get secret ghcr-secret >/dev/null 2>&1; then
    echo "⚠️  Existing ghcr-secret found. Deleting..."
    kubectl delete secret ghcr-secret
    echo "✅ Old secret deleted"
    echo ""
fi

# Prompt for credentials
echo "Enter your GitHub credentials:"
echo ""
read -p "GitHub Username: " GITHUB_USERNAME
read -sp "GitHub PAT (with read:packages scope): " GITHUB_PAT
echo ""
read -p "Email: " GITHUB_EMAIL
echo ""

# Create secret
echo "Creating ghcr-secret..."
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GITHUB_USERNAME" \
  --docker-password="$GITHUB_PAT" \
  --docker-email="$GITHUB_EMAIL" \
  --namespace=default

echo "✅ Secret created!"
echo ""

# Verify
echo "Verifying secret..."
kubectl get secret ghcr-secret
echo ""

# Restart deployments
echo "Restarting deployments to use new secret..."
kubectl rollout restart deployment/hostly-web 2>/dev/null || echo "Backend deployment not found"
kubectl rollout restart deployment/gatewayms 2>/dev/null || echo "Gateway deployment not found"
kubectl rollout restart deployment/hostly-react-front 2>/dev/null || echo "Frontend deployment not found"

echo ""
echo "=== Done ==="
echo ""
echo "Check pod status:"
echo "  kubectl get pods"
echo ""
echo "If pods still fail, check:"
echo "  1. PAT has 'read:packages' scope"
echo "  2. Package permissions in GitHub"
echo "  3. Pod events: kubectl describe pod <pod-name>"

