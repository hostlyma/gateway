#!/bin/bash
# Create backend secret

set -e

echo "=== Creating Backend Secret ==="
echo ""

# Check if secret already exists
if kubectl get secret hostly-web-secret >/dev/null 2>&1; then
    echo "⚠️  Secret already exists. Delete it first if you want to recreate:"
    echo "   kubectl delete secret hostly-web-secret"
    read -p "Delete and recreate? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete secret hostly-web-secret
    else
        echo "Exiting..."
        exit 0
    fi
fi

echo "Generating APP_KEY..."
APP_KEY=$(docker run --rm php:8.2-cli php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;" 2>/dev/null || echo "")

if [ -z "$APP_KEY" ]; then
    echo "⚠️  Could not generate APP_KEY automatically"
    echo "Please generate one manually:"
    echo "   docker run --rm php:8.2-cli php -r \"echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;\""
    read -p "Enter APP_KEY (or press Enter to skip): " APP_KEY
fi

echo ""
echo "Enter database credentials (must match postgres-secret):"
read -p "DB_USERNAME [hostly_user]: " DB_USERNAME
DB_USERNAME=${DB_USERNAME:-hostly_user}

read -sp "DB_PASSWORD: " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ DB_PASSWORD is required!"
    exit 1
fi

# Create secret from file or directly
if [ -f "secret.yaml" ]; then
    echo "Using secret.yaml file..."
    # Replace placeholders
    sed -i.bak "s/base64:CHANGE_THIS_TO_YOUR_APP_KEY/$APP_KEY/g" secret.yaml 2>/dev/null || \
    sed -i "s/base64:CHANGE_THIS_TO_YOUR_APP_KEY/$APP_KEY/g" secret.yaml
    sed -i.bak "s/DB_USERNAME: \"laravel\"/DB_USERNAME: \"$DB_USERNAME\"/g" secret.yaml 2>/dev/null || \
    sed -i "s/DB_USERNAME: \"laravel\"/DB_USERNAME: \"$DB_USERNAME\"/g" secret.yaml
    sed -i.bak "s/CHANGE_THIS_TO_SECURE_PASSWORD/$DB_PASSWORD/g" secret.yaml 2>/dev/null || \
    sed -i "s/CHANGE_THIS_TO_SECURE_PASSWORD/$DB_PASSWORD/g" secret.yaml
    
    kubectl apply -f secret.yaml
    rm -f secret.yaml.bak 2>/dev/null || true
else
    echo "Creating secret directly..."
    kubectl create secret generic hostly-web-secret \
        --from-literal=APP_KEY="$APP_KEY" \
        --from-literal=DB_USERNAME="$DB_USERNAME" \
        --from-literal=DB_PASSWORD="$DB_PASSWORD" \
        --namespace=default
fi

echo ""
echo "✅ Secret created!"
echo ""
echo "Verify:"
kubectl get secret hostly-web-secret

