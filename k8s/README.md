# Kubernetes Manifests

All Kubernetes manifests for the HostlyMA stack are organized in this directory.

## Directory Structure

```
k8s/
├── backend/          # Laravel backend (hostly-web)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── secret.yaml
├── frontend/         # React frontend (hostly-react-front)
│   ├── deployment.yaml
│   └── service.yaml
├── gateway/          # Nginx API Gateway (gatewayms)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── postgres/         # PostgreSQL database
    ├── postgres-pvc.yaml
    ├── postgres-secret.yaml
    ├── postgres-deployment.yaml
    └── postgres-service.yaml
```

## Deployment Order

Deploy components in this order:

1. **PostgreSQL** - Database must be ready first
2. **Backend** - Needs database connection
3. **Frontend** - Needs backend API
4. **Gateway** - Routes to all services

## Quick Deployment

### Apply All Manifests

```bash
# From gatewayms directory
cd k8s

# 1. PostgreSQL (database first)
kubectl apply -f postgres/

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# 2. Backend
kubectl apply -f backend/

# Run migrations
kubectl exec -it deployment/hostly-web -- php artisan migrate --force

# 3. Frontend
kubectl apply -f frontend/

# 4. Gateway (exposes everything externally)
kubectl apply -f gateway/
```

### Deploy Individual Components

```bash
# PostgreSQL only
kubectl apply -f k8s/postgres/

# Backend only
kubectl apply -f k8s/backend/

# Frontend only
kubectl apply -f k8s/frontend/

# Gateway only
kubectl apply -f k8s/gateway/
```

## Before Deployment

### 1. Update Secrets

**Backend Secret** (`backend/secret.yaml`):
```yaml
APP_KEY: "base64:YOUR_GENERATED_KEY"  # Generate with: php artisan key:generate
DB_PASSWORD: "YOUR_SECURE_PASSWORD"
```

**PostgreSQL Secret** (`postgres/postgres-secret.yaml`):
```yaml
POSTGRES_PASSWORD: "YOUR_SECURE_PASSWORD"  # Must match DB_PASSWORD above
```

### 2. Update ConfigMap (if needed)

Edit `backend/configmap.yaml` to update environment variables like:
- `APP_URL`
- `MAIL_*` settings
- Database connection settings

## Verification

```bash
# Check all pods
kubectl get pods

# Check all services
kubectl get svc

# Check ingress
kubectl get ingress

# Test endpoints
curl http://46.224.158.32/api/health
curl http://46.224.158.32/
```

## Cleanup

To remove everything:

```bash
# Remove in reverse order
kubectl delete -f gateway/
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f postgres/
```

## Component Details

### Backend (hostly-web)

- **Deployment**: 2 replicas
- **Service**: `hostly-web-service:80` (ClusterIP)
- **Health Check**: `/api/health`
- **ConfigMap**: Environment variables
- **Secret**: APP_KEY, DB credentials

### Frontend (hostly-react-front)

- **Deployment**: 2 replicas
- **Service**: `hostly-react-front-service:80` (ClusterIP)
- **Health Check**: `/`

### Gateway (gatewayms)

- **Deployment**: 2 replicas
- **Service**: `gatewayms-service:80` (ClusterIP)
- **Ingress**: External access point (ONLY one)
- **Health Check**: `/api/health` (proxied)

### PostgreSQL

- **Deployment**: 1 replica
- **Service**: `postgres-service:5432` (ClusterIP)
- **Storage**: 10Gi PVC
- **Health Check**: `pg_isready`

## Troubleshooting

```bash
# Check pod status
kubectl get pods -A

# Check logs
kubectl logs -f deployment/hostly-web
kubectl logs -f deployment/hostly-react-front
kubectl logs -f deployment/gatewayms
kubectl logs -f deployment/postgres

# Describe resources
kubectl describe pod <pod-name>
kubectl describe svc <service-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

## Notes

- All services are ClusterIP (internal only), except Gateway via Ingress
- Gateway is the single entry point for external traffic
- Secrets must be updated before deployment
- Database password must match in both backend and postgres secrets
- Health checks ensure zero-downtime rolling updates

