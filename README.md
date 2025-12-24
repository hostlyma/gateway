# Gateway MS - Nginx API Gateway

## Overview

This is the **API Gateway** component that routes all incoming traffic to the appropriate backend services. It's the single entry point for external traffic and handles routing based on URL patterns.

## Architecture

```
Internet (46.224.158.32)
    ↓
Kubernetes Ingress → gatewayms-service:80
    ↓
Gateway Nginx (this service)
    ├─> /api/*   → hostly-web-service:80 (Laravel API - JSON)
    ├─> /admin/* → hostly-web-service:80 (Laravel Blade - HTML)
    ├─> /css/*   → hostly-web-service:80 (Laravel static assets)
    ├─> /js/*    → hostly-web-service:80 (Laravel static assets)
    ├─> /images/*→ hostly-web-service:80 (Laravel static assets)
    ├─> /storage/*→ hostly-web-service:80 (Laravel storage)
    └─> /*       → hostly-react-front-service:80 (React SPA)
```

## Repository Structure

```
gatewayms/
├── Dockerfile                           # Nginx Alpine image
├── .github/
│   └── workflows/
│       └── deploy.yml                  # GitHub Actions CI/CD
├── nginx/
│   ├── nginx.conf                      # Main Nginx configuration
│   ├── conf.d/
│   │   └── default.conf                # Server block
│   └── locations/
│       ├── locations-api.conf          # API routes (/api/*)
│       ├── locations-admin.conf        # Admin routes (/admin/*) + static assets
│       └── locations-frontend.conf     # Frontend routes (/*)
└── k8s/
    ├── deployment.yaml                 # Kubernetes deployment
    ├── service.yaml                    # ClusterIP service
    └── ingress.yaml                    # External ingress (ONLY one)
```

## Routing Rules

### 1. API Routes (`/api/*`)

**File**: `nginx/locations/locations-api.conf`

- **Routes to**: `hostly-web-service:80`
- **Purpose**: JSON API responses from Laravel
- **Features**:
  - CORS headers (configurable)
  - Long timeouts (300s) for complex operations
  - No buffering (streaming responses)
  - Health check bypass

**Example**: `GET /api/users` → Laravel API

### 2. Admin Routes (`/admin/*`)

**File**: `nginx/locations/locations-admin.conf`

- **Routes to**: `hostly-web-service:80`
- **Purpose**: Blade HTML templates from Laravel
- **Features**:
  - Session cookie support
  - Cookie forwarding
  - No HTML caching
  - Standard timeouts (60s)

**Example**: `GET /admin/dashboard` → Laravel Blade

### 3. Static Assets (`/css/*`, `/js/*`, `/images/*`, `/storage/*`)

**File**: `nginx/locations/locations-admin.conf` (same file)

- **Routes to**: `hostly-web-service:80`
- **Purpose**: Laravel public directory assets
- **Features**:
  - Aggressive caching (1 year)
  - Cache-Control headers
  - Minimal logging

**Example**: `GET /css/app.css` → Laravel public directory

### 4. Frontend Routes (`/*`)

**File**: `nginx/locations/locations-frontend.conf`

- **Routes to**: `hostly-react-front-service:80`
- **Purpose**: React SPA (catch-all)
- **Features**:
  - SPA routing support
  - 404 fallback to index.html
  - WebSocket support (if needed)

**Example**: `GET /` or `GET /any-route` → React SPA

## Location Block Order

**CRITICAL**: The order of location blocks matters in Nginx. The configuration files are loaded in this order:

1. `locations-api.conf` - `/api/*` (most specific)
2. `locations-admin.conf` - `/admin/*`, `/css/*`, etc. (specific)
3. `locations-frontend.conf` - `/*` (catch-all, must be last)

## Docker Build

### Build Manually

```bash
docker build -t ghcr.io/hostlyma/gatewayms:latest .
docker push ghcr.io/hostlyma/gatewayms:latest
```

## Kubernetes Deployment

### Prerequisites

1. Kubernetes cluster running
2. Nginx Ingress Controller installed
3. GitHub secrets configured:
   - `KUBE_CONFIG`: Base64-encoded kubeconfig

### Centralized Deployment

**All Kubernetes manifests are in `k8s/` directory**. Deploy everything from there:

```bash
cd k8s

# Quick deployment (all components)
chmod +x deploy-all.sh
./deploy-all.sh

# Or deploy manually:
kubectl apply -f postgres/     # Database first
kubectl apply -f backend/      # Backend second
kubectl apply -f frontend/     # Frontend third
kubectl apply -f gateway/      # Gateway last
```

See `k8s/README.md` for detailed deployment instructions.

### Verify Deployment

```bash
kubectl get pods -l app=gatewayms
kubectl logs -f deployment/gatewayms
kubectl get svc gatewayms-service
kubectl get ingress gateway-ingress
```

## Configuration Details

### CORS Configuration

CORS is enabled for API routes in `locations-api.conf`. To restrict origins:

```nginx
# Replace '*' with specific origin
add_header 'Access-Control-Allow-Origin' 'https://yourdomain.com' always;
```

### Timeouts

- **API routes**: 300s (for long-running operations)
- **Admin routes**: 60s (standard web page timeouts)
- **Frontend routes**: 60s

### Buffering

- **API routes**: Buffering disabled (streaming)
- **Admin/Frontend**: Buffering enabled (better performance)

### Caching

- **Static assets**: 1 year cache
- **HTML pages**: No cache (always fresh)
- **API responses**: No cache (dynamic data)

## GitHub Actions CI/CD

### Setup

1. **Add GitHub Secret**:
   - Repository settings → Secrets → Actions
   - Add `KUBE_CONFIG` secret:
     ```bash
     cat /etc/kubernetes/admin.conf | base64 -w 0
     ```

2. **Workflow triggers**:
   - Push to `main` branch
   - Manual dispatch (workflow_dispatch)

## Ingress Configuration

The `ingress.yaml` file creates the **ONLY** external entry point:

- **Host**: `46.224.158.32` (or your domain)
- **Path**: `/`
- **Backend**: `gatewayms-service:80`
- **Ingress Class**: `nginx`

### Adding Domain Support

Edit `k8s/ingress.yaml`:

```yaml
spec:
  rules:
  - host: yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gatewayms-service
            port:
              number: 80
```

## Health Checks

- **Endpoint**: `GET /api/health` (proxied to backend)
- **Probe**: Kubernetes liveness/readiness checks
- **Interval**: 30s

## Logging

Logs are stored in `/var/log/nginx/`:

- `access.log` - All requests
- `error.log` - Errors
- `api_access.log` - API requests only
- `admin_access.log` - Admin requests only
- `frontend_access.log` - Frontend requests only

### View Logs

```bash
kubectl logs -f deployment/gatewayms
# Or exec into pod:
kubectl exec -it <pod-name> -- tail -f /var/log/nginx/access.log
```

## Troubleshooting

### Check Gateway Logs
```bash
kubectl logs -f deployment/gatewayms
```

### Test Routing
```bash
# Test API route
curl -v http://46.224.158.32/api/health

# Test admin route
curl -v http://46.224.158.32/admin

# Test frontend route
curl -v http://46.224.158.32/
```

### Verify Service Discovery
```bash
# From inside cluster
kubectl run curl-test --image=curlimages/curl --rm -it -- sh
# Inside pod:
curl http://hostly-web-service:80/api/health
curl http://hostly-react-front-service:80/
```

### Check Nginx Config
```bash
kubectl exec -it <pod-name> -- nginx -t
kubectl exec -it <pod-name> -- cat /etc/nginx/nginx.conf
```

### Common Issues

1. **404 on all routes**: Check service names and ports
2. **CORS errors**: Verify CORS headers in `locations-api.conf`
3. **Session not working**: Check cookie headers in `locations-admin.conf`
4. **Static assets 404**: Verify Laravel storage link

## Security Considerations

1. **Rate Limiting**: Consider adding rate limiting for API routes
2. **DDoS Protection**: Use Kubernetes network policies
3. **SSL/TLS**: Add TLS/HTTPS via Ingress annotations
4. **IP Whitelisting**: Restrict admin routes if needed

## Performance Tuning

- Worker processes: `auto` (based on CPU cores)
- Worker connections: `2048`
- Keepalive timeout: `65s`
- Gzip compression: Enabled
- Client body size: `100M` (adjust if needed)

## Notes

- This is the **ONLY** component with external access (via Ingress)
- All other services are ClusterIP (internal only)
- Location block order is critical for proper routing
- Health check endpoint bypasses logging for performance
- Static assets are aggressively cached for performance

