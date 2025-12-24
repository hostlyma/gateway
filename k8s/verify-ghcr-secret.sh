#!/bin/bash
# Verify GHCR secret and test image pull

echo "=== Verifying GHCR Secret ==="
echo ""

# Check secret exists
echo "1. Checking secret exists..."
kubectl get secret ghcr-secret || {
    echo "❌ Secret not found!"
    exit 1
}
echo "✅ Secret exists"
echo ""

# Decode and show secret (without exposing password)
echo "2. Secret details:"
kubectl get secret ghcr-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths."ghcr.io".username' | xargs -I {} echo "   Username: {}"
echo ""

# Test if we can pull the image (if docker is available on node)
echo "3. Testing image pull (if docker is available)..."
if command -v docker &> /dev/null; then
    # Extract credentials from secret
    USERNAME=$(kubectl get secret ghcr-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths."ghcr.io".username')
    PASSWORD=$(kubectl get secret ghcr-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths."ghcr.io".password')
    
    echo "   Testing login..."
    echo "$PASSWORD" | docker login ghcr.io -u "$USERNAME" --password-stdin 2>&1 | head -3
    
    echo "   Testing pull..."
    docker pull ghcr.io/hostlyma/backend:latest 2>&1 | head -5 || echo "   ⚠️  Pull failed - check PAT permissions"
else
    echo "   Docker not available on this node"
fi
echo ""

# Check pod status
echo "4. Checking pod status..."
kubectl get pods -l app=hostly-web 2>/dev/null || echo "   No backend pods found"
echo ""

# Check recent events
echo "5. Recent image pull events:"
kubectl get events --sort-by='.lastTimestamp' | grep -i "pull\|image\|backend" | tail -5 || echo "   No recent events"
echo ""

echo "=== Verification Complete ==="
echo ""
echo "If you see 403 errors, check:"
echo "1. PAT has 'read:packages' scope in GitHub"
echo "2. Package exists: https://github.com/hostlyma/backend/pkgs/container/backend"
echo "3. Package visibility (private packages need proper permissions)"
echo "4. Organization permissions (if package is in 'hostlyma' org)"

