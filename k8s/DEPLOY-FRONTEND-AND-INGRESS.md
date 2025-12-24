# Deploy Frontend and Configure Ingress for IP Access

## Overview

This guide will:
1. Deploy the frontend application
2. Configure access via IP address (46.224.158.32) until you get a domain name
3. Set up both Ingress and NodePort options for external access

## Step 1: Deploy Frontend

```bash
# Deploy frontend
kubectl apply -f gatewayms/k8s/frontend/

# Verify frontend is running
kubectl get pods -l app=hostly-react-front
kubectl get svc hostly-react-front-service
```

## Step 2: Choose Access Method

You have two options for accessing your application:

### Option A: NodePort (Simplest - Works Immediately)

This exposes the gateway directly on port 30080:

```bash
# Apply NodePort service
kubectl apply -f gatewayms/k8s/gateway/service-nodeport.yaml

# Open firewall (if needed)
sudo ufw allow 30080/tcp

# Access your application
# Frontend: http://46.224.158.32:30080/
# API: http://46.224.158.32:30080/api
# Admin: http://46.224.158.32:30080/admin
```

### Option B: Ingress (Recommended for Production)

This uses the ingress controller (if installed) and works on port 80:

```bash
# Check if ingress controller is installed
kubectl get ingressclass

# If nginx ingress controller exists, apply the updated ingress
kubectl apply -f gatewayms/k8s/gateway/ingress.yaml

# Check ingress status
kubectl get ingress gateway-ingress

# Access your application (if ingress controller is properly configured)
# Frontend: http://46.224.158.32/
# API: http://46.224.158.32/api
# Admin: http://46.224.158.32/admin
```

## Step 3: Verify Everything Works

```bash
# Check all pods are running
kubectl get pods

# Check all services
kubectl get svc

# Check ingress (if using Option B)
kubectl get ingress

# Test frontend from inside cluster
kubectl run test-frontend --rm -i --restart=Never --image=curlimages/curl -- \
  curl -I http://hostly-react-front-service/

# Test gateway from inside cluster
kubectl run test-gateway --rm -i --restart=Never --image=curlimages/curl -- \
  curl -I http://gatewayms-service/
```

## Step 4: Test External Access

### If using NodePort (Option A):
```bash
# From your local machine or browser
curl -I http://46.224.158.32:30080/
curl -I http://46.224.158.32:30080/api/health
```

### If using Ingress (Option B):
```bash
# From your local machine or browser
curl -I http://46.224.158.32/
curl -I http://46.224.158.32/api/health
```

## Troubleshooting

### Frontend not accessible

```bash
# Check frontend pods
kubectl get pods -l app=hostly-react-front
kubectl logs -l app=hostly-react-front

# Check frontend service
kubectl get svc hostly-react-front-service
kubectl describe svc hostly-react-front-service
```

### Gateway not routing correctly

```bash
# Check gateway pods
kubectl get pods -l app=gatewayms
kubectl logs -l app=gatewayms

# Check gateway service
kubectl get svc gatewayms-service
kubectl describe svc gatewayms-service

# Check nginx config in gateway
kubectl exec -it deployment/gatewayms -- cat /etc/nginx/conf.d/default.conf
```

### Ingress not working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx  # or -n kube-system

# Check ingress status
kubectl describe ingress gateway-ingress

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Firewall issues

```bash
# Check firewall status
sudo ufw status

# Allow required ports
sudo ufw allow 80/tcp      # For ingress
sudo ufw allow 30080/tcp   # For NodePort
sudo ufw allow 443/tcp     # For HTTPS (future)
```

## Architecture

```
Internet
   │
   ├─> Option A: http://46.224.158.32:30080 (NodePort)
   │   └─> gatewayms-service-nodeport:30080
   │       └─> gatewayms pods
   │           ├─> /api/* → hostly-backend-service
   │           ├─> /admin/* → hostly-backend-service
   │           └─> /* → hostly-react-front-service
   │
   └─> Option B: http://46.224.158.32 (Ingress)
       └─> Ingress Controller
           └─> gatewayms-service:80
               └─> gatewayms pods
                   ├─> /api/* → hostly-backend-service
                   ├─> /admin/* → hostly-backend-service
                   └─> /* → hostly-react-front-service
```

## When You Get a Domain Name

1. Update `gatewayms/k8s/gateway/ingress.yaml`:
   - Uncomment the domain name rule
   - Replace `yourdomain.com` with your actual domain
   - Point DNS A record to `46.224.158.32`

2. Apply updated ingress:
   ```bash
   kubectl apply -f gatewayms/k8s/gateway/ingress.yaml
   ```

3. Access via domain:
   - Frontend: `http://yourdomain.com/`
   - API: `http://yourdomain.com/api`
   - Admin: `http://yourdomain.com/admin`

