#!/bin/bash

# eShop Kubernetes - Simple Build & Push Script (Cloud Build)
# This script uses Docker Hub's infrastructure to build for linux/amd64

set -e

REGISTRY=${REGISTRY:-"aady12"}
TAG=${TAG:-"latest"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==================================================="
echo "eShop Cloud Build & Push"
echo "==================================================="
echo "Registry: $REGISTRY"
echo "Using registry: $REGISTRY"
echo ""
echo "Note: Make sure you're logged in to Docker Hub (docker login)"
echo ""

# Create dockerfiles directory
mkdir -p "$SCRIPT_DIR/dockerfiles"

# Service definitions
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

echo "Generating Dockerfiles..."
for service_info in "${services[@]}"; do
    IFS=':' read -r service project <<< "$service_info"
    
    cat > "$SCRIPT_DIR/dockerfiles/Dockerfile.$service" <<EOF
# Build stage uses linux/amd64 to avoid gRPC protoc ARM64 bugs
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src

COPY ["Directory.Build.props", "."]
COPY ["Directory.Build.targets", "."]
COPY ["Directory.Packages.props", "."]
COPY ["nuget.config", "."]

COPY ["src/", "src/"]

RUN dotnet restore "src/$project/$project.csproj"
RUN dotnet build "src/$project/$project.csproj" -c Release -o /app/build /p:GenerateDocumentationFile=false /p:NoWarn=1591 /p:GenerateOpenApiDocument=false

FROM build AS publish
RUN dotnet publish "src/$project/$project.csproj" -c Release -o /app/publish /p:UseAppHost=false /p:GenerateDocumentationFile=false /p:GenerateOpenApiDocument=false

# Runtime stage uses target platform (amd64 for GKE)
FROM --platform=\$TARGETPLATFORM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$project.dll"]
EOF
done

echo "✓ Generated all Dockerfiles"
echo ""

# Use default docker builder (not buildx)
export DOCKER_BUILDKIT=1

# Build and push each service
for service_info in "${services[@]}"; do
    IFS=':' read -r service project <<< "$service_info"
    
    echo "==========================================="
    echo "Building: $service"
    echo "==========================================="
    
    # Build for linux/amd64 using buildx with platform args
    docker buildx build \
        --platform linux/amd64 \
        -f "$SCRIPT_DIR/dockerfiles/Dockerfile.$service" \
        -t $REGISTRY/$service:$TAG \
        --load \
        "$ROOT_DIR"
    
    echo ""
    echo "Pushing: $REGISTRY/$service:$TAG"
    docker push $REGISTRY/$service:$TAG
    
    echo "✓ Completed $service"
    echo ""
done

echo ""
echo "==================================================="
echo "✓ All images built and pushed successfully!"
echo "==================================================="
echo ""
echo "Images pushed to Docker Hub:"
for service_info in "${services[@]}"; do
    IFS=':' read -r service project <<< "$service_info"
    echo "  - $REGISTRY/$service:$TAG"
done
echo ""
echo "Next steps:"
echo "  1. Push images: Already done!"
echo "  2. Deploy: cd k8s && ./deploy.sh"
