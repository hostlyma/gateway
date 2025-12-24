#!/bin/bash
# Script to generate Laravel APP_KEY

echo "=== Generating Laravel APP_KEY ==="
echo ""

# Method 1: Using PHP container
echo "Generating APP_KEY using PHP container..."
APP_KEY=$(docker run --rm php:8.2-cli php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;" 2>/dev/null)

if [ -z "$APP_KEY" ]; then
    # Method 2: Using openssl
    echo "Trying alternative method with openssl..."
    APP_KEY="base64:$(openssl rand -base64 32)"
fi

if [ -z "$APP_KEY" ]; then
    echo "Error: Could not generate APP_KEY"
    echo "Please generate manually:"
    echo "  docker run --rm php:8.2-cli php -r \"echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;\""
    exit 1
fi

echo ""
echo "Generated APP_KEY:"
echo "$APP_KEY"
echo ""
echo "Add this to gatewayms/k8s/backend/secret.yaml:"
echo "  APP_KEY: \"$APP_KEY\""
echo ""

