#!/bin/bash

# eShop Kubernetes - Build Docker Images Script
# This script builds Docker images for all eShop services

set -e

echo "Building eShop Docker images..."

# Set image registry (change this for your registry)
REGISTRY=${REGISTRY:-"aady12"}
TAG=${TAG:-"latest"}

# Get the root directory (parent of k8s/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building from root directory: $ROOT_DIR"
echo "Using registry: $REGISTRY"
echo ""

# Ask if user wants to push directly
read -p "Push images directly to Docker Hub after build? (yes/no): " -r PUSH_AFTER_BUILD
echo ""

# Build function
build_image() {
    local service=$1
    local project_path=$2
    
    echo "Building $service..."
    
    if [[ $PUSH_AFTER_BUILD =~ ^[Yy][Ee][Ss]$ ]]; then
        # Build and push directly (avoids local emulation issues)
        docker buildx build \
            --platform linux/amd64 \
            -f "$SCRIPT_DIR/dockerfiles/Dockerfile.$service" \
            -t $REGISTRY/$service:$TAG \
            --push \
            "$ROOT_DIR"
        echo "✓ Built and pushed $service"
    else
        # Build for native platform and load locally
        docker buildx build \
            -f "$SCRIPT_DIR/dockerfiles/Dockerfile.$service" \
            -t $REGISTRY/$service:$TAG \
            --load \
            "$ROOT_DIR"
        echo "✓ Built $service"
    fi
}

# Create dockerfiles directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/dockerfiles"

# Generate Dockerfiles for each service
echo "Generating Dockerfiles..."

services=(
    "identity-api:Identity.API"
    "basket-api:Basket.API"
    "catalog-api:Catalog.API"
    "ordering-api:Ordering.API"
    "webhooks-api:Webhooks.API"
    "order-processor:OrderProcessor"
    "payment-processor:PaymentProcessor"
    "webapp:WebApp"
    "webhooksclient:WebhookClient"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r service project <<< "$service_info"
    
    # Create Dockerfile for each service
    cat > "$SCRIPT_DIR/dockerfiles/Dockerfile.$service" <<EOF
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["Directory.Build.props", "."]
COPY ["Directory.Build.targets", "."]
COPY ["Directory.Packages.props", "."]
COPY ["nuget.config", "."]

COPY ["src/", "src/"]

RUN dotnet restore "src/$project/$project.csproj"
RUN dotnet build "src/$project/$project.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "src/$project/$project.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$project.dll"]
EOF
    
    build_image $service $project
done

echo ""
echo "✓ All images built successfully!"
echo ""
echo "To push images to a registry, run:"
echo "  docker push $REGISTRY/<service-name>:$TAG"
echo ""
echo "Or use: ./push-images.sh"
