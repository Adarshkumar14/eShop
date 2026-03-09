#!/bin/bash

# eShop Kubernetes - Push Docker Images Script
# This script pushes Docker images to a container registry

set -e

REGISTRY=${REGISTRY:-"aady12"}
TAG=${TAG:-"latest"}

echo "Pushing eShop Docker images to registry: $REGISTRY"
echo ""

services=(
    "identity-api"
    "basket-api"
    "catalog-api"
    "ordering-api"
    "webhooks-api"
    "order-processor"
    "payment-processor"
    "webapp"
    "webhooksclient"
)

for service in "${services[@]}"; do
    echo "Pushing $service..."
    docker push $REGISTRY/$service:$TAG
    echo "✓ Pushed $service"
done

echo ""
echo "✓ All images pushed successfully!"
