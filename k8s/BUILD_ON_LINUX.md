# Building eShop Docker Images on Linux VM

This guide explains how to build the eShop Docker images on a Linux VM (native amd64), which avoids all the ARM64 emulation issues encountered on Mac.

## 🖥️ Linux VM Setup

### Prerequisites

1. **Linux VM** (Ubuntu 20.04+ or similar)
2. **Docker installed**
3. **Git installed**
4. **Docker Hub account** (username: aady12)

### Quick Setup Script

```bash
#!/bin/bash
# Run this on your Linux VM to set up the environment

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Git
sudo apt-get install -y git

# Log out and log back in for docker group to take effect
echo "Please log out and log back in for Docker permissions to take effect"
```

## 📥 Clone Repository

```bash
# Clone the repository
git clone https://github.com/Adarshkumar14/eShop.git
cd eShop

# Checkout the kubernetes feature branch
git checkout feature/kubernetes-deployment
```

## 🔑 Docker Hub Login

```bash
docker login
# Username: aady12
# Password: <your-docker-hub-password>
```

## 🏗️ Build All Images

The build script will automatically:
- Generate Dockerfiles for all 9 services
- Build each service using .NET 10 preview
- Push to Docker Hub (`aady12/*:latest`)

```bash
cd k8s
./build-and-push.sh
```

### Expected Build Time

On a Linux VM with decent resources:
- **identity-api**: ~3-4 minutes
- **basket-api**: ~4-5 minutes (has gRPC)
- **catalog-api**: ~4-5 minutes (has gRPC)
- **ordering-api**: ~4-5 minutes (has gRPC)
- **webhooks-api**: ~3-4 minutes
- **order-processor**: ~2-3 minutes
- **payment-processor**: ~2-3 minutes
- **webapp**: ~4-5 minutes
- **webhooksclient**: ~2-3 minutes

**Total**: ~30-40 minutes for all 9 services

## 📦 What Gets Built

The script builds and pushes these images:

```
aady12/identity-api:latest
aady12/basket-api:latest
aady12/catalog-api:latest
aady12/ordering-api:latest
aady12/webhooks-api:latest
aady12/order-processor:latest
aady12/payment-processor:latest
aady12/webapp:latest
aady12/webhooksclient:latest
```

## 🔍 Monitor Build Progress

The script will output:
- ✓ Generated all Dockerfiles
- Building: <service-name>...
- Pushing: aady12/<service>:latest
- ✓ Completed <service-name>

## ⚠️ Troubleshooting

### Build Failure

If a build fails:

```bash
# View the last few lines of output
docker build --progress=plain \
  -f k8s/dockerfiles/Dockerfile.<service-name> \
  -t aady12/<service-name>:latest \
  .

# Check Docker disk space
docker system df

# Clean up if needed
docker system prune -a
```

### Network Issues

If NuGet restore is slow:

```bash
# Use a different NuGet feed mirror
export NUGET_FEED="https://api.nuget.org/v3/index.json"
```

### Memory Issues

If builds fail due to memory:

```bash
# Check available memory
free -h

# Increase swap if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## ✅ Verify Images

After building, verify all images:

```bash
# List local images
docker images | grep aady12

# Verify images on Docker Hub
docker pull aady12/identity-api:latest
docker pull aady12/basket-api:latest
# ... etc
```

## 🚀 Deploy to GKE

Once all images are built and pushed:

```bash
# On your local Mac (connected to GKE)
cd /path/to/eShop/k8s
./deploy.sh
```

## 📊 Build Optimization Tips

### Parallel Builds

If your Linux VM has sufficient resources (8+ CPU cores, 16GB+ RAM), you can build multiple services in parallel:

```bash
# Build 2-3 services at a time
./build-service.sh identity-api &
./build-service.sh basket-api &
./build-service.sh catalog-api &
wait

# Continue with remaining services
./build-service.sh ordering-api &
./build-service.sh webhooks-api &
wait
```

### Use Docker BuildKit

BuildKit is already enabled in the script, but you can further optimize:

```bash
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain  # For detailed logs
```

### Cache Strategy

To speed up rebuilds:

```bash
# Keep the build cache between builds
# The script already reuses layers from previous builds

# To force a complete rebuild:
docker buildx prune -a
./build-and-push.sh
```

## 🔄 CI/CD Integration (Future)

For automated builds, consider setting up GitHub Actions:

```yaml
name: Build and Push Docker Images

on:
  push:
    branches: [main, feature/kubernetes-deployment]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and Push
        run: |
          cd k8s
          ./build-and-push.sh
```

## 📝 Notes

- **Linux VM Advantages**:
  - Native amd64 architecture (no emulation)
  - Better .NET 10 preview stability
  - Faster builds
  - No gRPC protoc issues

- **Why Not Mac**:
  - ARM64 architecture requires emulation for amd64
  - .NET 10 preview has stability issues under emulation
  - gRPC protoc tools crash on ARM64

## 🆘 Support

If you encounter issues:
1. Check the build logs
2. Verify Docker and .NET SDK versions
3. Ensure sufficient disk space and memory
4. Check Docker Hub credentials

## 📚 Related Documentation

- [Main Deployment Guide](README.md)
- [Deployment Checklist](DEPLOYMENT_CHECKLIST.md)
- [Kubernetes Commands Reference](COMMANDS.md)
