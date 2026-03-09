# Useful Kubernetes Commands for eShop

Quick reference for common Kubernetes operations with the eShop application.

## Deployment Commands

```bash
# Deploy everything
./deploy.sh

# Deploy using kustomize
kubectl apply -k k8s/

# Deploy specific component
kubectl apply -f k8s/services/catalog-api.yaml

# Update deployment after changes
kubectl apply -k k8s/
```

## Viewing Resources

```bash
# Get all resources in eshop namespace
kubectl get all -n eshop

# Get pods with labels
kubectl get pods -l app.kubernetes.io/part-of=eshop -n eshop

# Get pods with wide output (shows node info)
kubectl get pods -n eshop -o wide

# Watch pods in real-time
kubectl get pods -n eshop -w

# Get services
kubectl get svc -n eshop

# Get ingress
kubectl get ingress -n eshop

# Get persistent volume claims
kubectl get pvc -n eshop

# Get secrets
kubectl get secrets -n eshop

# Get configmaps
kubectl get configmap -n eshop
```

## Logs and Debugging

```bash
# View logs for webapp
kubectl logs -f deployment/webapp -n eshop

# View logs for specific pod
kubectl logs <pod-name> -n eshop

# View logs for all containers in pod
kubectl logs <pod-name> -n eshop --all-containers

# View previous container logs (after restart)
kubectl logs <pod-name> -n eshop --previous

# View logs for last 100 lines
kubectl logs deployment/webapp -n eshop --tail=100

# View logs with timestamps
kubectl logs deployment/webapp -n eshop --timestamps

# Stream logs from multiple pods
kubectl logs -l app=webapp -n eshop -f

# Get events sorted by time
kubectl get events -n eshop --sort-by='.lastTimestamp'

# Describe pod (shows events, config, status)
kubectl describe pod <pod-name> -n eshop

# Describe service
kubectl describe svc webapp -n eshop

# Get pod YAML
kubectl get pod <pod-name> -n eshop -o yaml
```

## Scaling

```bash
# Scale webapp to 3 replicas
kubectl scale deployment webapp --replicas=3 -n eshop

# Scale catalog-api to 5 replicas
kubectl scale deployment catalog-api --replicas=5 -n eshop

# Auto-scale based on CPU
kubectl autoscale deployment webapp --cpu-percent=70 --min=2 --max=10 -n eshop

# View horizontal pod autoscalers
kubectl get hpa -n eshop
```

## Updates and Rollbacks

```bash
# Update image for webapp
kubectl set image deployment/webapp webapp=eshop/webapp:v2.0 -n eshop

# Check rollout status
kubectl rollout status deployment/webapp -n eshop

# View rollout history
kubectl rollout history deployment/webapp -n eshop

# Rollback to previous version
kubectl rollout undo deployment/webapp -n eshop

# Rollback to specific revision
kubectl rollout undo deployment/webapp --to-revision=2 -n eshop

# Pause rollout
kubectl rollout pause deployment/webapp -n eshop

# Resume rollout
kubectl rollout resume deployment/webapp -n eshop

# Restart deployment (rolling restart)
kubectl rollout restart deployment/webapp -n eshop
```

## Accessing Applications

```bash
# Port forward webapp
kubectl port-forward svc/webapp 8080:8080 -n eshop

# Port forward identity-api
kubectl port-forward svc/identity-api 5001:8080 -n eshop

# Port forward RabbitMQ management
kubectl port-forward svc/rabbitmq 15672:15672 -n eshop

# Port forward PostgreSQL
kubectl port-forward svc/postgres 5432:5432 -n eshop

# Port forward Redis
kubectl port-forward svc/redis 6379:6379 -n eshop

# Get external IP of LoadBalancer service
kubectl get svc webapp-external -n eshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# For Minikube - get service URL
minikube service webapp-external -n eshop --url
```

## Executing Commands in Pods

```bash
# Execute bash in webapp pod
kubectl exec -it deployment/webapp -n eshop -- /bin/bash

# Execute sh in postgres pod
kubectl exec -it deployment/postgres -n eshop -- /bin/sh

# Run psql in postgres
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres

# Run redis-cli
kubectl exec -it deployment/redis -n eshop -- redis-cli

# Execute one-off command
kubectl exec deployment/webapp -n eshop -- env

# Test HTTP endpoint from inside cluster
kubectl exec -it deployment/webapp -n eshop -- curl http://catalog-api:8080/health
```

## Database Operations

```bash
# Connect to PostgreSQL
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres

# List databases
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres -c "\l"

# Connect to specific database
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres -d catalogdb

# Run SQL query
kubectl exec -it deployment/postgres -n eshop -- psql -U postgres -d catalogdb -c "SELECT * FROM catalog_items LIMIT 5;"

# Dump database
kubectl exec deployment/postgres -n eshop -- pg_dump -U postgres catalogdb > catalogdb_backup.sql

# Restore database
cat catalogdb_backup.sql | kubectl exec -i deployment/postgres -n eshop -- psql -U postgres catalogdb
```

## Redis Operations

```bash
# Connect to Redis
kubectl exec -it deployment/redis -n eshop -- redis-cli

# Check Redis keys
kubectl exec -it deployment/redis -n eshop -- redis-cli KEYS '*'

# Get Redis info
kubectl exec -it deployment/redis -n eshop -- redis-cli INFO

# Flush all data (use with caution!)
kubectl exec -it deployment/redis -n eshop -- redis-cli FLUSHALL
```

## Secrets and ConfigMaps

```bash
# View secret (base64 encoded)
kubectl get secret eshop-secrets -n eshop -o yaml

# Decode specific secret
kubectl get secret eshop-secrets -n eshop -o jsonpath='{.data.postgres-password}' | base64 -d

# Edit secret
kubectl edit secret eshop-secrets -n eshop

# View configmap
kubectl get configmap eshop-config -n eshop -o yaml

# Edit configmap
kubectl edit configmap eshop-config -n eshop

# Create secret from literal
kubectl create secret generic my-secret --from-literal=key=value -n eshop

# Create configmap from file
kubectl create configmap my-config --from-file=config.json -n eshop
```

## Resource Usage

```bash
# View resource usage for nodes
kubectl top nodes

# View resource usage for pods
kubectl top pods -n eshop

# View resource usage for specific pod
kubectl top pod <pod-name> -n eshop

# Sort pods by CPU usage
kubectl top pods -n eshop --sort-by=cpu

# Sort pods by memory usage
kubectl top pods -n eshop --sort-by=memory
```

## Network Debugging

```bash
# Test DNS resolution
kubectl exec -it deployment/webapp -n eshop -- nslookup catalog-api

# Test service connectivity
kubectl exec -it deployment/webapp -n eshop -- curl http://catalog-api:8080/health

# Test external connectivity
kubectl exec -it deployment/webapp -n eshop -- curl https://www.google.com

# View service endpoints
kubectl get endpoints -n eshop

# View service endpoint details
kubectl describe endpoints catalog-api -n eshop
```

## Cleanup

```bash
# Delete specific deployment
kubectl delete deployment webapp -n eshop

# Delete specific service
kubectl delete svc webapp -n eshop

# Delete all resources with label
kubectl delete all -l app=webapp -n eshop

# Delete everything using kustomize
kubectl delete -k k8s/

# Delete namespace (deletes everything in it)
kubectl delete namespace eshop

# Delete PVCs
kubectl delete pvc --all -n eshop

# Force delete stuck pod
kubectl delete pod <pod-name> -n eshop --grace-period=0 --force
```

## Backup and Migration

```bash
# Export all resources to YAML
kubectl get all -n eshop -o yaml > eshop-backup.yaml

# Backup persistent volumes
kubectl get pvc -n eshop -o yaml > eshop-pvc-backup.yaml

# Export secrets
kubectl get secrets -n eshop -o yaml > eshop-secrets-backup.yaml

# Export configmaps
kubectl get configmaps -n eshop -o yaml > eshop-configmaps-backup.yaml
```

## Troubleshooting

```bash
# Check cluster info
kubectl cluster-info

# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check resource quotas
kubectl get resourcequota -n eshop

# Check limit ranges
kubectl get limitrange -n eshop

# Check network policies
kubectl get networkpolicy -n eshop

# Check RBAC
kubectl get rolebindings -n eshop
kubectl get roles -n eshop

# Validate YAML without applying
kubectl apply -k k8s/ --dry-run=client

# Server-side validation
kubectl apply -k k8s/ --dry-run=server

# Explain resource fields
kubectl explain deployment.spec.template.spec.containers

# Get API resources
kubectl api-resources

# Get API versions
kubectl api-versions
```

## Monitoring Integration

```bash
# If using Prometheus operator
kubectl get servicemonitor -n eshop

# If using metrics-server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/eshop/pods
```

## Context and Namespace Management

```bash
# Set default namespace
kubectl config set-context --current --namespace=eshop

# View current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Create alias for easier access (add to .bashrc or .zshrc)
alias k='kubectl'
alias kn='kubectl -n eshop'
alias kgp='kubectl get pods -n eshop'
alias kgs='kubectl get svc -n eshop'
alias kl='kubectl logs -f -n eshop'
```

## Useful Aliases

Add these to your shell profile for faster operations:

```bash
# Basic aliases
alias k='kubectl'
alias keshop='kubectl -n eshop'

# Pod operations
alias kgp='kubectl get pods -n eshop'
alias kdp='kubectl describe pod -n eshop'
alias kep='kubectl edit pod -n eshop'
alias kdel='kubectl delete pod -n eshop'

# Deployment operations
alias kgd='kubectl get deployment -n eshop'
alias kdd='kubectl describe deployment -n eshop'
alias ked='kubectl edit deployment -n eshop'

# Service operations
alias kgs='kubectl get svc -n eshop'
alias kds='kubectl describe svc -n eshop'

# Logs
alias kl='kubectl logs -f -n eshop'
alias klp='kubectl logs -f -n eshop --previous'

# Execute
alias kex='kubectl exec -it -n eshop'

# Port forward
alias kpf='kubectl port-forward -n eshop'
```

## Performance and Load Testing

```bash
# Run load test from inside cluster
kubectl run load-test --image=busybox --rm -it --restart=Never -n eshop -- /bin/sh -c "while true; do wget -q -O- http://webapp:8080; done"

# Run Apache Bench from pod
kubectl run ab-test --image=httpd --rm -it --restart=Never -n eshop -- ab -n 1000 -c 10 http://webapp:8080/
```

## Quick Health Check Script

Save this as `health-check.sh`:

```bash
#!/bin/bash
echo "=== eShop Health Check ==="
echo ""
echo "Pods Status:"
kubectl get pods -n eshop
echo ""
echo "Services:"
kubectl get svc -n eshop
echo ""
echo "Checking Health Endpoints:"
for service in identity-api basket-api catalog-api ordering-api webhooks-api webapp; do
    echo -n "$service: "
    kubectl exec -it deployment/$service -n eshop -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "N/A"
done
```

Remember to make it executable: `chmod +x health-check.sh`
