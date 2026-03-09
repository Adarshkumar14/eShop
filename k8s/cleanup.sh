#!/bin/bash

# eShop Kubernetes - Cleanup Script
# This script removes the eShop application from Kubernetes

set -e

echo "Cleaning up eShop from Kubernetes..."
echo ""

read -p "Are you sure you want to delete the eShop deployment? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete using kustomize
kubectl delete -k k8s/ || true

# Optionally delete PVCs
read -p "Do you want to delete persistent data (PVCs)? (yes/no): " -r
echo

if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deleting PVCs..."
    kubectl delete pvc --all -n eshop || true
fi

echo ""
echo "✓ Cleanup complete!"
