# Environment Variables Reference

Complete list of environment variables used by the Hostly-web Laravel application.

## Configuration Files

- **ConfigMap** (`configmap.yaml`): Non-sensitive configuration
- **Secret** (`secret.yaml`): Sensitive credentials and API keys

## Required Variables

### Application Core (ConfigMap)

```yaml
APP_NAME: "HostlyMA"
APP_ENV: "production"
APP_DEBUG: "false"
APP_URL: "http://46.224.158.32"
```

### Application Key (Secret)

```yaml
APP_KEY: "base64:YOUR_GENERATED_KEY"  # REQUIRED - Generate with: php artisan key:generate
```

### Database (ConfigMap + Secret)

```yaml
# ConfigMap
DB_CONNECTION: "pgsql"
DB_DATABASE: "laravel"  # or "postgres" or "hostly"

# Secret
DB_USERNAME: "hostly_user"  # Must match PostgreSQL user
DB_PASSWORD: "Diamantine@2"  # Must match PostgreSQL password

# Deployment (hardcoded)
DB_HOST: "postgres-service"  # Kubernetes service name
DB_PORT: "5432"
```

## Optional Variables

### Session & Cache (ConfigMap)

```yaml
SESSION_DRIVER: "database"
SESSION_LIFETIME: "120"
CACHE_DRIVER: "database"
QUEUE_CONNECTION: "database"
```

### Mail Configuration (ConfigMap + Secret)

```yaml
# ConfigMap
MAIL_MAILER: "smtp"
MAIL_HOST: "smtp.mailtrap.io"
MAIL_PORT: "2525"
MAIL_ENCRYPTION: "tls"
MAIL_FROM_ADDRESS: "noreply@hostlyma.com"
MAIL_FROM_NAME: "HostlyMA"

# Secret
MAIL_USERNAME: ""  # SMTP username
MAIL_PASSWORD: ""  # SMTP password
```

### Logging (ConfigMap)

```yaml
LOG_CHANNEL: "stack"
LOG_LEVEL: "info"
```

### Filesystem (ConfigMap)

```yaml
FILESYSTEM_DISK: "local"  # or "s3" for AWS S3
```

## Third-Party Services (Secret)

### Hospitable API

```yaml
HOSPITABLE_API_KEY: "your_api_key"
HOSPITABLE_API_SECRET: "your_api_secret"
HOSPITABLE_TOKEN: "your_token"
HOSPITABLE_WEBHOOK_SECRET: "your_webhook_secret"
```

### Channex API

```yaml
CHANNEX_API_KEY: "your_channex_api_key"
```

### Google OAuth

```yaml
GOOGLE_CLIENT_ID: "your_google_client_id"
GOOGLE_CLIENT_SECRET: "your_google_client_secret"
GOOGLE_REDIRECT_URI: "https://your-domain.com/auth/google/callback"
```

### Tuya IoT

```yaml
TUYA_CLIENT_ID: "your_tuya_client_id"
TUYA_CLIENT_SECRET: "your_tuya_client_secret"
```

### TTLock

```yaml
TTLOCK_CLIENT_ID: "your_ttlock_client_id"
TTLOCK_CLIENT_SECRET: "your_ttlock_client_secret"
```

### Stripe Payment

```yaml
STRIPE_KEY: "your_stripe_public_key"
STRIPE_SECRET: "your_stripe_secret_key"
STRIPE_WEBHOOK_SECRET: "your_stripe_webhook_secret"
```

### AWS (S3/SES)

```yaml
AWS_ACCESS_KEY_ID: "your_aws_access_key"
AWS_SECRET_ACCESS_KEY: "your_aws_secret_key"
AWS_BUCKET: "your_s3_bucket_name"
AWS_DEFAULT_REGION: "us-east-1"
```

### Other Services

```yaml
JWT_SECRET: "your-jwt-secret"
RESEND_KEY: "your_resend_key"
POSTMARK_TOKEN: "your_postmark_token"
```

## Service URLs (ConfigMap - defaults)

These have defaults but can be overridden:

```yaml
HOSPITABLE_BASE_URL: "https://api.hospitable.com/v1"
HOSPITABLE_CONNECT_BASE_URL: "https://connect.hospitable.com/api/v1"
CHANNEX_BASE_URL: "https://staging.channex.io"
TTLOCK_BASE_URL: "https://euapi.ttlock.com"
```

## Redis (if using Redis instead of database)

```yaml
REDIS_HOST: "127.0.0.1"
REDIS_PASSWORD: ""
REDIS_PORT: "6379"
REDIS_QUEUE_CONNECTION: "default"
```

## How to Add New Variables

1. **Non-sensitive variables** → Add to `configmap.yaml`
2. **Sensitive variables** (API keys, passwords) → Add to `secret.yaml`
3. **Apply changes:**
   ```bash
   kubectl apply -f gatewayms/k8s/backend/configmap.yaml
   kubectl apply -f gatewayms/k8s/backend/secret.yaml
   kubectl rollout restart deployment/hostly-web
   ```

## Verification

Check if variables are loaded correctly:

```bash
# Check ConfigMap
kubectl get configmap hostly-web-config -o yaml

# Check Secret (values are base64 encoded)
kubectl get secret hostly-web-secret -o yaml

# Check environment in running pod
kubectl exec deployment/hostly-web -- env | grep -E "APP_|DB_|MAIL_"
```

