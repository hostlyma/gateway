#!/bin/bash
# Test pgAdmin connection from inside and outside

echo "=== Testing pgAdmin Connection ==="
echo ""

echo "1. Checking pgAdmin logs (last 30 lines)..."
kubectl logs deployment/pgadmin --tail=30
echo ""

echo "2. Testing connection from inside cluster..."
kubectl run test-pgadmin --rm -i --restart=Never --image=curlimages/curl -- curl -I http://pgadmin-service:80 2>&1
echo ""

echo "3. Testing direct pod connection..."
POD_IP=$(kubectl get pod -l app=pgadmin -o jsonpath='{.items[0].status.podIP}')
echo "Pod IP: $POD_IP"
kubectl run test-pod-ip --rm -i --restart=Never --image=curlimages/curl -- curl -I http://$POD_IP:80 2>&1
echo ""

echo "4. Checking if pgAdmin is listening on port 80..."
kubectl exec deployment/pgadmin -- netstat -tlnp 2>/dev/null | grep 80 || kubectl exec deployment/pgadmin -- ss -tlnp 2>/dev/null | grep 80
echo ""

echo "5. Testing NodePort from node..."
curl -I http://localhost:30433 2>&1 | head -5
echo ""

echo "=== Test Complete ==="

