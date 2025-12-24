# Manual Image Building Guide

If you need to build and push Docker images manually (before CI/CD runs), use these instructions.

## Prerequisites

1. Docker installed locally
2. GitHub Personal Access Token (PAT) with `write:packages` permission
3. Logged into GitHub Container Registry

## Login to GitHub Container Registry

```bash
# Login to ghcr.io
echo $GITHUB_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Or if you have the token in a variable:
docker login ghcr.io -u YOUR_GITHUB_USERNAME -p YOUR_GITHUB_PAT
```

## Build and Push Images

### Gateway (gatewayms)

```bash
cd gatewayms

# Build the image
docker build -t ghcr.io/hostlyma/gatewayms:latest .

# Push to registry
docker push ghcr.io/hostlyma/gatewayms:latest
```

### Backend (hostly-web)

```bash
cd Hostly-web

# Build the image
docker build -t ghcr.io/hostlyma/hostly-web:latest .

# Push to registry
docker push ghcr.io/hostlyma/hostly-web:latest
```

### Frontend (hostly-react-front)

```bash
cd Hostly-react-front

# Build the image with build args
docker build \
  --build-arg REACT_APP_API_URL=/api \
  -t ghcr.io/hostlyma/hostly-react-front:latest \
  .

# Push to registry
docker push ghcr.io/hostlyma/hostly-react-front:latest
```

## Build All Images Script

Save this as `build-all.sh`:

```bash
#!/bin/bash

# Set your GitHub username and PAT
GITHUB_USERNAME="YOUR_USERNAME"
GITHUB_PAT="YOUR_PAT"

# Login to GitHub Container Registry
echo $GITHUB_PAT | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Build and push Gateway
echo "Building gatewayms..."
cd gatewayms
docker build -t ghcr.io/hostlyma/gatewayms:latest .
docker push ghcr.io/hostlyma/gatewayms:latest
cd ..

# Build and push Backend
echo "Building hostly-web..."
cd Hostly-web
docker build -t ghcr.io/hostlyma/hostly-web:latest .
docker push ghcr.io/hostlyma/hostly-web:latest
cd ..

# Build and push Frontend
echo "Building hostly-react-front..."
cd Hostly-react-front
docker build --build-arg REACT_APP_API_URL=/api -t ghcr.io/hostlyma/hostly-react-front:latest .
docker push ghcr.io/hostlyma/hostly-react-front:latest
cd ..

echo "All images built and pushed successfully!"
```

Make it executable and run:
```bash
chmod +x build-all.sh
./build-all.sh
```

## Verify Images

```bash
# List images in your registry (requires GitHub CLI or web interface)
# Or test pull:
docker pull ghcr.io/hostlyma/gatewayms:latest
docker pull ghcr.io/hostlyma/hostly-web:latest
docker pull ghcr.io/hostlyma/hostly-react-front:latest
```

## Troubleshooting

### Authentication Errors

If you get authentication errors:
1. Verify your PAT has `write:packages` permission
2. Make sure you're logged in: `docker login ghcr.io`
3. Check image visibility settings in GitHub

### Build Errors

- **Gateway**: Make sure `nginx/` directory exists with all config files
- **Backend**: Ensure Laravel dependencies are installed
- **Frontend**: Make sure `npm install --legacy-peer-deps` works locally first

### Push Errors

- Verify image name matches your GitHub organization/username
- Check that package permissions are set correctly in GitHub
- Ensure you're using the correct registry: `ghcr.io`

## After Building

Once images are pushed, your Kubernetes deployments should be able to pull them:

```bash
# Check if pods can pull images
kubectl get pods
kubectl describe pod <pod-name>

# If images are available, apply deployments
cd gatewayms/k8s
kubectl apply -f gateway/
```

