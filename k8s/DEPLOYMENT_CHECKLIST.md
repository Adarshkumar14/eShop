# eShop Kubernetes Deployment Checklist

Use this checklist to ensure a smooth deployment of eShop to Kubernetes.

## Pre-Deployment Checklist

### ✅ Environment Setup
- [ ] Kubernetes cluster is running and accessible
- [ ] `kubectl` is installed and configured
- [ ] Docker is installed and running
- [ ] You have sufficient cluster resources:
  - Minimum: 4 CPUs, 8GB RAM
  - Recommended: 8 CPUs, 16GB RAM

### ✅ Configuration Review
- [ ] Review and update `k8s/base/secrets.yaml`
  - [ ] Change `postgres-password` from default
  - [ ] Change `rabbitmq-password` from default
  - [ ] Generate secure `jwt-secret`
- [ ] Review `k8s/base/configmap.yaml` for environment settings
- [ ] Update storage sizes in infrastructure YAMLs if needed
- [ ] Update resource limits based on your cluster capacity

### ✅ Container Registry (if using remote cluster)
- [ ] Container registry is accessible
- [ ] Docker is logged in to registry: `docker login <registry>`
- [ ] Update REGISTRY variable: `export REGISTRY=<your-registry>`
- [ ] Update image references in deployment YAMLs to use your registry

### ✅ Networking (for production)
- [ ] NGINX Ingress Controller is installed (if using ingress)
- [ ] DNS records are configured (if using custom domain)
- [ ] SSL/TLS certificates are ready (for HTTPS)
- [ ] Firewall rules allow traffic to LoadBalancer/NodePort

## Deployment Steps

### Step 1: Build Images
```bash
cd k8s
./build-images.sh
```
- [ ] All 9 images built successfully
- [ ] No build errors

### Step 2: Push Images (if remote cluster)
```bash
export REGISTRY=<your-registry>
./push-images.sh
```
- [ ] All images pushed to registry
- [ ] Images are accessible from cluster

### Step 3: Deploy to Kubernetes
```bash
./deploy.sh
```
- [ ] Namespace created: `eshop`
- [ ] All infrastructure pods running (postgres, redis, rabbitmq)
- [ ] All service pods running
- [ ] All app pods running
- [ ] No CrashLoopBackOff or ImagePullBackOff errors

### Step 4: Verify Deployment
```bash
kubectl get pods -n eshop
kubectl get svc -n eshop
```
- [ ] All pods show STATUS: Running
- [ ] All pods pass READY checks
- [ ] Services have ClusterIP assigned
- [ ] External service has EXTERNAL-IP (if using LoadBalancer)

## Post-Deployment Verification

### ✅ Health Checks
```bash
# Check webapp health
kubectl exec -it deployment/webapp -n eshop -- curl http://localhost:8080/health

# Check identity-api health
kubectl exec -it deployment/identity-api -n eshop -- curl http://localhost:8080/health
```
- [ ] All health endpoints return 200 OK

### ✅ Database Verification
```bash
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres -c "\l"
```
- [ ] catalogdb exists
- [ ] identitydb exists
- [ ] orderingdb exists
- [ ] webhooksdb exists

### ✅ Application Access
- [ ] Can access webapp (via port-forward, LoadBalancer, or Ingress)
- [ ] Home page loads successfully
- [ ] Can browse catalog
- [ ] Can log in (test with default users)

### ✅ Service Communication
- [ ] Services can communicate internally
- [ ] RabbitMQ message bus is working
- [ ] Redis caching is functional

## Monitoring Setup (Optional but Recommended)

### ✅ Logging
- [ ] Can view pod logs: `kubectl logs -f deployment/webapp -n eshop`
- [ ] Logs are readable and show no critical errors

### ✅ Metrics (if installed)
- [ ] Prometheus is scraping metrics
- [ ] Grafana dashboards are displaying data

### ✅ Alerts (for production)
- [ ] Alert rules are configured
- [ ] Alert notifications are working

## Production Readiness Checklist

### ✅ Security
- [ ] All default passwords changed
- [ ] Secrets are properly encrypted
- [ ] Network policies are configured
- [ ] RBAC is properly set up
- [ ] TLS/SSL is enabled for external access
- [ ] Security scanning completed (no critical vulnerabilities)

### ✅ High Availability
- [ ] Stateless services have replicas >= 2
- [ ] Database has backup/replication strategy
- [ ] Redis has persistence enabled
- [ ] RabbitMQ has clustering (if needed)
- [ ] Pod Disruption Budgets configured

### ✅ Resource Management
- [ ] Resource requests and limits are set
- [ ] Namespace quotas configured
- [ ] Horizontal Pod Autoscaling configured (optional)

### ✅ Backup & Recovery
- [ ] Database backup strategy in place
- [ ] Backup schedule configured
- [ ] Backup restoration tested
- [ ] Disaster recovery plan documented

### ✅ Documentation
- [ ] Deployment runbook created
- [ ] Access procedures documented
- [ ] Troubleshooting guide prepared
- [ ] Rollback procedure documented

## Common Issues & Solutions

### Issue: Pods stuck in Pending state
**Solution:**
- Check if cluster has sufficient resources: `kubectl describe node`
- Check PVC status: `kubectl get pvc -n eshop`
- Check events: `kubectl get events -n eshop`

### Issue: ImagePullBackOff
**Solution:**
- Verify images are built: `docker images | grep eshop`
- Check imagePullSecrets if using private registry
- Verify registry credentials

### Issue: CrashLoopBackOff
**Solution:**
- Check pod logs: `kubectl logs <pod-name> -n eshop`
- Check environment variables: `kubectl describe pod <pod-name> -n eshop`
- Verify database connectivity

### Issue: Database connection errors
**Solution:**
- Verify postgres is running: `kubectl get pods -l app=postgres -n eshop`
- Check connection strings in secrets
- Test database connectivity from a pod

### Issue: Services not communicating
**Solution:**
- Verify all services have ClusterIP: `kubectl get svc -n eshop`
- Check DNS resolution: `kubectl exec -it deployment/webapp -n eshop -- nslookup identity-api`
- Check network policies

## Rollback Procedure

If deployment fails or issues arise:

```bash
# Quick rollback
kubectl rollout undo deployment/<deployment-name> -n eshop

# Or delete and redeploy previous version
./cleanup.sh
# Fix issues
./deploy.sh
```

## Sign-off

Deployment completed by: ___________________

Date: ___________________

Environment: [ ] Dev [ ] Staging [ ] Production

Notes:
_____________________________________________
_____________________________________________
_____________________________________________
