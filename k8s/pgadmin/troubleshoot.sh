#!/bin/bash
# Troubleshooting script for pgAdmin connection issues

echo "=== pgAdmin Troubleshooting ==="
echo ""

echo "1. Checking pgAdmin pod status..."
kubectl get pods -l app=pgadmin
echo ""

echo "2. Checking pgAdmin service..."
kubectl get svc pgadmin-service
echo ""

echo "3. Checking pod logs (last 20 lines)..."
kubectl logs -l app=pgadmin --tail=20
echo ""

echo "4. Checking if pod is ready..."
kubectl get pods -l app=pgadmin -o jsonpath='{.items[0].status.conditions[*].type}{"\n"}'
kubectl get pods -l app=pgadmin -o jsonpath='{.items[0].status.phase}{"\n"}'
echo ""

echo "5. Checking service endpoints..."
kubectl get endpoints pgadmin-service
echo ""

echo "6. Testing port from inside cluster..."
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -- curl -I http://pgadmin-service:80 2>&1 || echo "Connection test failed"
echo ""

echo "7. Checking firewall status (if ufw is installed)..."
ufw status | grep 30433 || echo "Port 30433 not found in firewall rules"
echo ""

echo "=== Troubleshooting Complete ==="
echo ""
echo "Common fixes:"
echo "1. Wait for pod to be fully ready: kubectl wait --for=condition=ready pod -l app=pgadmin --timeout=120s"
echo "2. Open firewall: sudo ufw allow 30433/tcp"
echo "3. Check if service is NodePort: kubectl get svc pgadmin-service"
echo "4. Check pod logs for errors: kubectl logs -f deployment/pgadmin"

