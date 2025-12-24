# Frontend Deployment Guide

## Quick Deploy

```bash
# Deploy frontend
kubectl apply -f gatewayms/k8s/frontend/

# Check status
kubectl get pods -l app=hostly-react-front
kubectl get svc hostly-react-front-service
```

## Verify Frontend is Running

```bash
# Check pods
kubectl get pods -l app=hostly-react-front

# Check logs
kubectl logs -l app=hostly-react-front

# Test from inside cluster
kubectl run test-frontend --rm -i --restart=Never --image=curlimages/curl -- curl http://hostly-react-front-service/
```

## Access Frontend

The frontend is accessible through the gateway:
- **Via Gateway**: `http://46.224.158.32/` (routes to frontend)
- **Direct (internal)**: `hostly-react-front-service:80`

