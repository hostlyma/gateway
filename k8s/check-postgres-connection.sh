#!/bin/bash
# Script to test PostgreSQL connection from the node

echo "=== Testing PostgreSQL Connection ==="
echo ""

echo "1. Checking if PostgreSQL pod is running..."
kubectl get pods -l app=postgres
echo ""

echo "2. Checking PostgreSQL service..."
kubectl get svc postgres-service
echo ""

echo "3. Testing connection from inside the cluster..."
kubectl run postgres-client --rm -it --restart=Never --image=postgres:15-alpine -- psql -h postgres-service -U hostly_user -d hostly -c "SELECT version();" || echo "Connection failed"
echo ""

echo "4. Checking if NodePort is accessible..."
echo "Testing port 30432 on node IP..."
nc -zv localhost 30432 2>&1 || echo "Port check failed (nc might not be installed)"
echo ""

echo "5. Checking firewall status (if ufw is installed)..."
ufw status 2>/dev/null || echo "ufw not installed or not active"
echo ""

echo "=== Connection Test Complete ==="
echo ""
echo "If connection fails, check:"
echo "1. Firewall rules - allow port 30432"
echo "2. PostgreSQL pod logs: kubectl logs -l app=postgres"
echo "3. Service endpoints: kubectl get endpoints postgres-service"

