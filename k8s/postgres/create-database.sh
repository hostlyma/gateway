#!/bin/bash
# Script to create databases in PostgreSQL
# Since PostgreSQL skips initialization when data directory exists,
# you may need to manually create databases

set -e

echo "=== Creating PostgreSQL Databases ==="
echo ""

# Get pod name
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "Error: PostgreSQL pod not found"
    exit 1
fi

echo "PostgreSQL pod: $POD_NAME"
echo ""

# Get credentials from secret
POSTGRES_USER=$(kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)
POSTGRES_PASSWORD=$(kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)

echo "Creating databases..."
echo ""

# Create the 'hostly' database (if it doesn't exist)
echo "Creating database 'hostly'..."
kubectl exec -it $POD_NAME -- psql -U $POSTGRES_USER -d postgres -c "CREATE DATABASE hostly;" 2>/dev/null || echo "Database 'hostly' may already exist"
echo ""

# Create the 'laravel' database (if it doesn't exist) - for backend
echo "Creating database 'laravel'..."
kubectl exec -it $POD_NAME -- psql -U $POSTGRES_USER -d postgres -c "CREATE DATABASE laravel;" 2>/dev/null || echo "Database 'laravel' may already exist"
echo ""

# List all databases
echo "=== Available Databases ==="
kubectl exec -it $POD_NAME -- psql -U $POSTGRES_USER -d postgres -c "\l"
echo ""

echo "=== Done ==="
echo ""
echo "You can now run migrations to set up your database schema."

