# ⚠️ Build Images First!

Before deploying to Kubernetes, you **must** build and push the Docker images to GitHub Container Registry.

## Quick Solution

### Option 1: Push to GitHub (Recommended)

The easiest way is to push your code to trigger GitHub Actions:

```bash
# In each repository (gatewayms, hostly-web, hostly-react-front)
git add .
git commit -m "Initial commit for CI/CD"
git push origin main
```

GitHub Actions will automatically:
1. Build the Docker images
2. Push them to `ghcr.io/hostlyma/*`
3. Deploy to Kubernetes

### Option 2: Build Manually

If you need to build images manually, see `../BUILD-IMAGES.md` for detailed instructions.

Quick manual build:
```bash
# Login to GitHub Container Registry
docker login ghcr.io -u YOUR_USERNAME -p YOUR_PAT

# Build and push each image
cd gatewayms && docker build -t ghcr.io/hostlyma/gatewayms:latest . && docker push ghcr.io/hostlyma/gatewayms:latest
cd ../Hostly-web && docker build -t ghcr.io/hostlyma/hostly-web:latest . && docker push ghcr.io/hostlyma/hostly-web:latest
cd ../Hostly-react-front && docker build --build-arg REACT_APP_API_URL=/api -t ghcr.io/hostlyma/hostly-react-front:latest . && docker push ghcr.io/hostlyma/hostly-react-front:latest
```

## Check if Images Exist

Before deploying, verify images exist:

```bash
# Try to pull each image
docker pull ghcr.io/hostlyma/gatewayms:latest
docker pull ghcr.io/hostlyma/hostly-web:latest
docker pull ghcr.io/hostlyma/hostly-react-front:latest
```

Or check in GitHub:
- Go to your GitHub organization/username
- Click on "Packages"
- Look for the images

## Common Error

If you see:
```
Failed to pull image "ghcr.io/hostlyma/gatewayms:latest": not found
```

**This means the image doesn't exist yet!** You must build and push it first (see options above).

## Deployment Order

1. ✅ **Build and push images** (this step!)
2. ✅ Create Kubernetes secrets (ghcr-secret, backend secrets, postgres secrets)
3. ✅ Deploy PostgreSQL
4. ✅ Deploy Backend
5. ✅ Deploy Frontend
6. ✅ Deploy Gateway

---

**Remember**: Images must exist in the registry before Kubernetes can pull them!


