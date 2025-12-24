#!/bin/bash
# Create hostly database if it doesn't exist

set -e

echo "=== Creating 'hostly' Database ==="
echo ""

# Get postgres pod name
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ Error: PostgreSQL pod not found"
    exit 1
fi

echo "PostgreSQL pod: $POD_NAME"
echo ""

# Get credentials from secret
POSTGRES_USER=$(kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)
POSTGRES_PASSWORD=$(kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)

echo "Creating 'hostly' database..."
kubectl exec -it $POD_NAME -- psql -U $POSTGRES_USER -d postgres -c "CREATE DATABASE hostly;" 2>/dev/null && echo "✅ Database 'hostly' created" || echo "⚠️  Database 'hostly' may already exist"
echo ""

# List all databases
echo "=== Available Databases ==="
kubectl exec -it $POD_NAME -- psql -U $POSTGRES_USER -d postgres -c "\l"
echo ""

echo "=== Done ==="

