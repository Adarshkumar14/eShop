# eShop Kubernetes Deployment Guide

This directory contains Kubernetes manifests and deployment scripts for deploying the eShop reference application to a Kubernetes cluster.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Detailed Deployment Steps](#detailed-deployment-steps)
- [Configuration](#configuration)
- [Accessing the Application](#accessing-the-application)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Production Considerations](#production-considerations)
- [Cleanup](#cleanup)

## 🔧 Prerequisites

### Required Tools

- **Docker**: For building container images
- **kubectl**: Kubernetes command-line tool
- **Kubernetes Cluster**: One of the following:
  - Minikube (local development)
  - Kind (Kubernetes in Docker)
  - Docker Desktop with Kubernetes
  - AKS (Azure Kubernetes Service)
  - EKS (Amazon Elastic Kubernetes Service)
  - GKE (Google Kubernetes Engine)

### Install kubectl

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

### Local Kubernetes Options

#### Option 1: Minikube

```bash
# Install Minikube
brew install minikube

# Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable Ingress addon
minikube addons enable ingress
```

#### Option 2: Docker Desktop

- Install Docker Desktop
- Enable Kubernetes in Docker Desktop settings
- Wait for Kubernetes to start

#### Option 3: Kind

```bash
# Install Kind
brew install kind

# Create a cluster
kind create cluster --name eshop
```

## 🏗️ Architecture Overview

The eShop application consists of the following components:

### Infrastructure Components
- **PostgreSQL**: Database with pgvector extension (4 databases: catalog, identity, ordering, webhooks)
- **Redis**: Caching and session storage
- **RabbitMQ**: Message broker for event bus

### Microservices
- **Identity API**: Authentication and authorization service
- **Basket API**: Shopping basket management
- **Catalog API**: Product catalog service
- **Ordering API**: Order processing service
- **Webhooks API**: Webhook management
- **Order Processor**: Background order processing worker
- **Payment Processor**: Background payment processing worker

### Web Applications
- **WebApp**: Main e-commerce web application (Blazor)
- **Webhooks Client**: Webhook client application

### Networking
- **Ingress**: NGINX Ingress Controller for external access
- **ClusterIP Services**: Internal service-to-service communication

## 🚀 Quick Start

### 1. Build Docker Images

```bash
cd k8s
chmod +x *.sh
./build-images.sh
```

This will build all Docker images with the tag `eshop/<service>:latest`.

### 2. (Optional) Push to Registry

If deploying to a remote cluster, push images to a container registry:

```bash
# Login to your registry
docker login <your-registry>

# Set registry and push
export REGISTRY=<your-registry>/eshop
./push-images.sh
```

Then update image references in the YAML files to use your registry.

### 3. Deploy to Kubernetes

```bash
./deploy.sh
```

This script will:
- Create the `eshop` namespace
- Deploy infrastructure components (PostgreSQL, Redis, RabbitMQ)
- Deploy all microservices and applications
- Wait for all components to be ready
- Display access information

### 4. Access the Application

For local development (Minikube/Kind/Docker Desktop):

```bash
kubectl port-forward svc/webapp 8080:8080 -n eshop
```

Then open: http://localhost:8080

## 📝 Detailed Deployment Steps

### Step 1: Review and Update Configuration

#### Secrets (`base/secrets.yaml`)

**⚠️ IMPORTANT**: Update the secrets before deploying to production!

```yaml
# Generate secure passwords
postgres-password: "<your-secure-password>"
rabbitmq-password: "<your-secure-password>"
jwt-secret: "<your-secure-jwt-key>"
```

#### ConfigMap (`base/configmap.yaml`)

Review and update environment-specific settings:
- ASPNETCORE_ENVIRONMENT
- Service URLs (if using external services)
- Logging configuration

### Step 2: Customize Resource Limits

Edit deployment files to adjust CPU/Memory based on your cluster capacity:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Step 3: Build Container Images

```bash
./build-images.sh
```

**For custom registry:**

```bash
export REGISTRY=myregistry.azurecr.io/eshop
export TAG=v1.0.0
./build-images.sh
```

### Step 4: Deploy Infrastructure First

For a staged deployment:

```bash
# Deploy namespace and base config
kubectl apply -f base/

# Deploy infrastructure
kubectl apply -f infrastructure/

# Wait for infrastructure to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n eshop --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n eshop --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n eshop --timeout=300s
```

### Step 5: Deploy Services and Apps

```bash
# Deploy services
kubectl apply -f services/

# Deploy apps
kubectl apply -f apps/

# Deploy ingress
kubectl apply -f ingress/
```

### Step 6: Verify Deployment

```bash
# Check all pods
kubectl get pods -n eshop

# Check services
kubectl get svc -n eshop

# Check ingress
kubectl get ingress -n eshop
```

## ⚙️ Configuration

### Using Kustomize

The deployment can also be managed using Kustomize:

```bash
# Deploy everything
kubectl apply -k k8s/

# View resources before applying
kubectl kustomize k8s/
```

### Environment Variables

Key environment variables are defined in:
- `base/configmap.yaml`: Non-sensitive configuration
- `base/secrets.yaml`: Sensitive data (passwords, connection strings)

### Persistent Storage

Persistent Volume Claims (PVCs) are created for:
- PostgreSQL: 10Gi
- Redis: 1Gi
- RabbitMQ: 5Gi

Adjust storage sizes in the infrastructure YAML files based on your needs.

## 🌐 Accessing the Application

### Local Development

#### Port Forwarding (Recommended)

```bash
# Web Application
kubectl port-forward svc/webapp 8080:8080 -n eshop

# Identity API
kubectl port-forward svc/identity-api 5001:8080 -n eshop

# RabbitMQ Management UI
kubectl port-forward svc/rabbitmq 15672:15672 -n eshop
```

#### Minikube

```bash
# Get the webapp URL
minikube service webapp-external -n eshop --url
```

### Production/Cloud

The deployment includes a LoadBalancer service (`webapp-external`):

```bash
# Get external IP
kubectl get svc webapp-external -n eshop

# Wait for EXTERNAL-IP to be assigned
kubectl get svc webapp-external -n eshop -w
```

### Ingress

If using the Ingress controller:

1. Update your `/etc/hosts` file:
   ```
   <INGRESS-IP> eshop.local
   ```

2. Access via: http://eshop.local

## 🔍 Monitoring and Troubleshooting

### View Logs

```bash
# View webapp logs
kubectl logs -f deployment/webapp -n eshop

# View identity-api logs
kubectl logs -f deployment/identity-api -n eshop

# View all pods logs
kubectl logs -l app.kubernetes.io/part-of=eshop -n eshop --tail=50
```

### Check Pod Status

```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n eshop

# Get events
kubectl get events -n eshop --sort-by='.lastTimestamp'
```

### Database Access

```bash
# Connect to PostgreSQL
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres

# List databases
\l

# Connect to specific database
\c catalogdb
```

### Redis Access

```bash
# Connect to Redis CLI
kubectl exec -it deployment/redis -n eshop -- redis-cli

# Test connection
PING
```

### RabbitMQ Management

```bash
# Port forward RabbitMQ Management UI
kubectl port-forward svc/rabbitmq 15672:15672 -n eshop

# Access at: http://localhost:15672
# Default credentials: guest/guest (change in production!)
```

### Common Issues

#### Pods not starting

```bash
# Check pod status
kubectl get pods -n eshop

# View pod events
kubectl describe pod <pod-name> -n eshop

# Check logs
kubectl logs <pod-name> -n eshop
```

#### ImagePullBackOff Error

- Ensure Docker images are built: `./build-images.sh`
- For remote registry, verify image push and registry credentials
- Check imagePullSecrets if using private registry

#### Database Connection Errors

- Verify PostgreSQL is running: `kubectl get pods -l app=postgres -n eshop`
- Check connection strings in secrets: `kubectl get secret eshop-secrets -n eshop -o yaml`
- Ensure databases are created (check postgres logs)

## 🏭 Production Considerations

### Security

1. **Update Secrets**: Generate strong passwords and JWT secrets
2. **Use Secret Management**: Consider using:
   - Sealed Secrets
   - External Secrets Operator
   - Cloud provider secret services (Azure Key Vault, AWS Secrets Manager, GCP Secret Manager)
3. **Network Policies**: Implement network policies to restrict pod-to-pod communication
4. **RBAC**: Configure Role-Based Access Control
5. **TLS/SSL**: Enable HTTPS with proper certificates

### High Availability

1. **Increase Replicas**: Scale stateless services
   ```bash
   kubectl scale deployment webapp --replicas=3 -n eshop
   ```

2. **Database Replication**: Use PostgreSQL replication or managed database service

3. **Redis Cluster**: Deploy Redis in cluster mode for HA

4. **RabbitMQ Cluster**: Deploy RabbitMQ as a StatefulSet with clustering

### Resource Management

1. **Resource Quotas**: Set namespace resource quotas
2. **Horizontal Pod Autoscaling**: Configure HPA for auto-scaling
3. **Vertical Pod Autoscaling**: Use VPA for right-sizing pods

### Monitoring and Observability

1. **Prometheus + Grafana**: Install for metrics collection and visualization
2. **ELK/EFK Stack**: Deploy for centralized logging
3. **Jaeger/Zipkin**: Implement distributed tracing
4. **Health Checks**: Already configured (liveness/readiness probes)

### Backup and Disaster Recovery

1. **Database Backups**: Regular PostgreSQL backups
2. **PVC Snapshots**: Use volume snapshots for data persistence
3. **GitOps**: Use ArgoCD or Flux for declarative deployments

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build images
        run: |
          cd k8s
          ./build-images.sh
      
      - name: Push images
        run: |
          cd k8s
          export REGISTRY=${{ secrets.REGISTRY }}
          ./push-images.sh
      
      - name: Deploy to K8s
        run: |
          cd k8s
          ./deploy.sh
```

## 🧹 Cleanup

### Remove Deployment

```bash
./cleanup.sh
```

Or manually:

```bash
# Delete all resources
kubectl delete -k k8s/

# Delete namespace
kubectl delete namespace eshop

# Delete PVCs (if cleanup.sh didn't)
kubectl delete pvc --all -n eshop
```

### Remove Images

```bash
# List images
docker images | grep eshop

# Remove images
docker rmi $(docker images -q 'eshop/*')
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire/)
- [eShop GitHub Repository](https://github.com/dotnet/eshop)
- [Kustomize Documentation](https://kustomize.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## 🤝 Contributing

For issues or improvements to this Kubernetes deployment, please refer to the main eShop repository.

## 📄 License

This deployment configuration follows the same license as the eShop project.
