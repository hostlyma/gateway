# Quick Create Backend Secret

## Option 1: Using the YAML file (Recommended)

1. **Generate APP_KEY:**
   ```bash
   docker run --rm php:8.2-cli php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;"
   ```

2. **Edit `secret.yaml`:**
   - Replace `base64:CHANGE_THIS_TO_YOUR_APP_KEY` with your generated key
   - Database credentials are already correct (matching postgres-secret)

3. **Apply:**
   ```bash
   kubectl apply -f gatewayms/k8s/backend/secret.yaml
   ```

## Option 2: Create directly (Quick)

```bash
# Generate APP_KEY
APP_KEY=$(docker run --rm php:8.2-cli php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;")

# Create secret
kubectl create secret generic hostly-web-secret \
  --from-literal=APP_KEY="$APP_KEY" \
  --from-literal=DB_USERNAME="hostly_user" \
  --from-literal=DB_PASSWORD="Diamantine@2" \
  --namespace=default
```

## Option 3: Use the script

```bash
chmod +x gatewayms/k8s/backend/create-secret.sh
./gatewayms/k8s/backend/create-secret.sh
```

## Verify

```bash
kubectl get secret hostly-web-secret
kubectl describe secret hostly-web-secret
```

## Then deploy

```bash
kubectl apply -f gatewayms/k8s/backend/
```

