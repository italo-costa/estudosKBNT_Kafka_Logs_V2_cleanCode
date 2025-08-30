# Configurações Kubernetes - Resource Specifications

Este documento detalha todas as configurações de recursos e especificações dos deployments Kubernetes.

## Zookeeper StatefulSet

### Configurações de Recursos
```yaml
resources:
  requests:
    memory: "256Mi"      # Mínimo garantido
    cpu: "100m"          # 0.1 CPU cores
  limits:
    memory: "512Mi"      # Máximo permitido
    cpu: "250m"          # 0.25 CPU cores
```

### Especificações de Storage
- **Data Volume**: 5Gi per instance (ReadWriteOnce)
- **Logs Volume**: 5Gi per instance (ReadWriteOnce)
- **Total Storage**: 30Gi (3 replicas × 10Gi each)

### Network Configuration
- **Client Port**: 2181 (Zookeeper client connections)
- **Follower Port**: 2888 (Follower communication)
- **Election Port**: 3888 (Leader election)

### High Availability Setup
- **Replicas**: 3 (odd number for quorum)
- **Service Type**: ClusterIP + Headless Service
- **Anti-Affinity**: Recommended for production

## Kafka Cluster

### Broker Resource Specifications
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### Storage Configuration
- **Data Volume**: 10Gi per broker
- **Replication Factor**: 2 (minimum for HA)
- **Partitions**: 3 per topic (load distribution)

## Producer Service

### Resource Configuration
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"
```

### Scaling Configuration
- **Initial Replicas**: 3
- **Auto-scaling**: Based on CPU/Memory usage
- **Load Balancer**: Service mesh or ingress controller

## Consumer Service

### Resource Configuration
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"
```

### Consumer Group Configuration
- **Group ID**: log-consumer-group
- **Auto Commit**: false (manual commit for reliability)
- **Max Poll Records**: 100

## Monitoring Stack

### Prometheus Server
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### Grafana Dashboard
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## Production Recommendations

### Resource Tuning
1. **CPU Limits**: Start conservative, monitor usage
2. **Memory Limits**: Set based on JVM heap + system memory
3. **Storage**: Use SSD for Kafka data, regular disk for logs

### High Availability
1. **Pod Disruption Budgets**: Ensure minimum replicas
2. **Node Affinity**: Spread across availability zones
3. **Health Checks**: Liveness and readiness probes

### Performance Optimization
1. **JVM Tuning**: Heap size, GC configuration
2. **Network Policies**: Secure inter-service communication
3. **Resource Quotas**: Prevent resource starvation

## Security Configuration

### Network Policies
- Kafka brokers: Internal cluster communication only
- Producer/Consumer: HTTP ingress + Kafka egress
- Monitoring: Metrics scraping endpoints

### RBAC Configuration
- Service accounts for each component
- Minimal required permissions
- Secret management for credentials
