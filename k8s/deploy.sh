#!/bin/bash

# eShop Kubernetes - Deployment Script
# This script deploys the eShop application to Kubernetes

set -e

echo "Deploying eShop to Kubernetes..."
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to a Kubernetes cluster."
    echo "Please configure kubectl to connect to your cluster."
    exit 1
fi

echo "✓ Connected to Kubernetes cluster"
echo ""

# Deploy using kustomize
echo "Applying Kubernetes manifests..."
kubectl apply -k k8s/

echo ""
echo "Waiting for deployments to be ready..."
echo ""

# Wait for infrastructure to be ready
echo "Waiting for infrastructure components..."
kubectl wait --for=condition=ready pod -l app=postgres -n eshop --timeout=180s
kubectl wait --for=condition=ready pod -l app=redis -n eshop --timeout=180s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n eshop --timeout=180s

echo ""
echo "Infrastructure is ready!"
echo ""

# Wait for services to be ready
echo "Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=identity-api -n eshop --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=basket-api -n eshop --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=catalog-api -n eshop --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=ordering-api -n eshop --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=webhooks-api -n eshop --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=webapp -n eshop --timeout=180s || true

echo ""
echo "✓ eShop deployed successfully!"
echo ""

# Get service information
echo "Service Information:"
echo "===================="
kubectl get svc -n eshop

echo ""
echo "Pod Status:"
echo "==========="
kubectl get pods -n eshop

echo ""
echo "Access the application:"
echo "======================="

# Check if LoadBalancer is available
EXTERNAL_IP=$(kubectl get svc webapp-external -n eshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$EXTERNAL_IP" ]; then
    echo "For local development (Minikube/Kind), use port-forward:"
    echo "  kubectl port-forward svc/webapp 8080:8080 -n eshop"
    echo ""
    echo "Then access: http://localhost:8080"
else
    echo "External IP: http://$EXTERNAL_IP"
fi

echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/webapp -n eshop"
echo ""
echo "To delete the deployment:"
echo "  kubectl delete -k k8s/"
