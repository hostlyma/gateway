#!/bin/bash
# Fix secret not found issue

set -e

echo "=== Fixing Secret Issue ==="
echo ""

# Check secret exists
echo "1. Checking secret exists..."
kubectl get secret hostly-web-secret || {
    echo "❌ Secret not found! Creating it..."
    exit 1
}
echo "✅ Secret exists"
echo ""

# Check which namespace
echo "2. Checking namespaces..."
SECRET_NS=$(kubectl get secret hostly-web-secret --all-namespaces -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "default")
POD_NS=$(kubectl get pods -l app=hostly-web -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "default")

echo "Secret namespace: $SECRET_NS"
echo "Pod namespace: $POD_NS"
echo ""

if [ "$SECRET_NS" != "$POD_NS" ]; then
    echo "⚠️  Namespace mismatch! Copying secret..."
    kubectl get secret hostly-web-secret -n $SECRET_NS -o yaml | \
        sed "s/namespace: $SECRET_NS/namespace: $POD_NS/" | \
        kubectl apply -f -
    echo "✅ Secret copied to $POD_NS namespace"
fi
echo ""

# Delete pods to force restart
echo "3. Deleting pods to force restart with secret..."
kubectl delete pods -l app=hostly-web --force --grace-period=0
echo "✅ Pods deleted"
echo ""

# Wait for new pods
echo "4. Waiting for new pods..."
sleep 5
kubectl wait --for=condition=ready pod -l app=hostly-web --timeout=120s || {
    echo "⚠️  Pods not ready yet. Checking status..."
    kubectl get pods -l app=hostly-web
}
echo ""

# Check pod status
echo "5. Pod status:"
kubectl get pods -l app=hostly-web
echo ""

# Check events
echo "6. Recent events:"
kubectl get events --sort-by='.lastTimestamp' | grep -i "hostly-web\|secret" | tail -5
echo ""

echo "=== Done ==="

