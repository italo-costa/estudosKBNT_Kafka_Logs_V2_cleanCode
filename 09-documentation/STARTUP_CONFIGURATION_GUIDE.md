# =============================================================================
# KBNT Enhanced Kafka Publication Logging System
# Startup Configuration and Timing Guide
# =============================================================================

# ESTIMATED STARTUP TIMES FOR COMPLETE ENVIRONMENT
# =============================================================================

## Prerequisites Check: ~30 seconds
- Verify kubectl, docker, maven installations
- Test Kubernetes cluster connectivity
- Validate workspace structure

## Infrastructure Deployment Phase: ~4-6 minutes
### 1. Namespace Setup: 10 seconds
- Create kbnt-system namespace
- Apply labels and annotations

### 2. PostgreSQL Database: 60 seconds  
- Deploy PostgreSQL 15 with custom configuration
- Initialize kbnt_consumption_db database
- Wait for readiness and liveness probes
- Estimated ready time: 1 minute

### 3. Red Hat AMQ Streams (Kafka): 120 seconds
- Install/verify Strimzi operator (if needed: +60s)
- Deploy 3-broker Kafka cluster with Zookeeper
- Configure security and performance settings
- Estimated ready time: 2-3 minutes (first install can take 4-5 minutes)

### 4. Kafka Topics Creation: 30 seconds
- stock-updates (3 partitions, 3 replicas)
- high-priority-stock-updates (3 partitions, 3 replicas)  
- stock-updates-retry (3 partitions, 3 replicas)
- stock-updates-dlt (1 partition, 3 replicas)
- publication-logs (3 partitions, 3 replicas)
- Wait for topic operator to create all topics

## Application Services Phase: ~3-4 minutes
### 5. Producer Service (Microservice A): 90 seconds
- Maven build and package (~20s)
- Docker image creation (~15s)
- Kubernetes deployment (~30s)
- Application startup and health checks (~25s)
- Estimated ready time: 1.5 minutes

### 6. Consumer Service (Microservice B): 90 seconds
- Maven build and package (~25s)
- Docker image creation (~20s)
- Kubernetes deployment (~25s)
- Application startup and health checks (~20s)
- Estimated ready time: 1.5 minutes

## Verification and Testing Phase: ~2 minutes
### 7. Health Checks: 60 seconds
- PostgreSQL connectivity test
- Kafka cluster status verification
- Producer service health endpoint
- Consumer service health endpoint
- Service stabilization wait

### 8. End-to-End Workflow Test: 60 seconds
- Port forwarding setup (~10s)
- Send test message via Producer API (~5s)
- Message processing through Kafka (~15s)
- Consumer processing and external API calls (~20s)
- Verification of consumption logs (~10s)

# =============================================================================
# TOTAL ESTIMATED TIME: 8-12 MINUTES
# =============================================================================

**First-time deployment**: 10-15 minutes (includes Strimzi operator installation)
**Subsequent deployments**: 6-8 minutes (infrastructure already in place)

# =============================================================================
# DETAILED LOGGING CONFIGURATION
# =============================================================================

## Log Levels by Component
```yaml
Producer Service Logging:
  com.estudoskbnt.kafka: INFO
  org.springframework.kafka: INFO  
  org.apache.kafka: WARN
  root: WARN

Consumer Service Logging:
  com.estudoskbnt.consumer: INFO
  org.springframework.kafka: INFO
  org.apache.kafka: WARN
  org.hibernate.SQL: DEBUG (development only)
  root: WARN

Kafka/AMQ Streams Logging:
  kafka.root.logger.level: INFO
  kafka.controller: INFO
  kafka.log.cleaner: WARN
  kafka.producer: INFO
  kafka.consumer: INFO
```

## Log Patterns
```yaml
Console Pattern: "%d{HH:mm:ss.SSS} [%thread] %-5level [%X{correlationId}] %logger{36} - %msg%n"
File Pattern: "%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level [%X{correlationId}] %logger{36} - %msg%n"
```

## Key Log Markers to Monitor
```bash
# Infrastructure Ready Markers
[INFO] Namespace 'kbnt-system' is ready and configured
[SUCCESS] PostgreSQL deployed and ready  
[SUCCESS] Kafka cluster deployed and ready
[SUCCESS] All Kafka topics created and ready

# Application Ready Markers  
[SUCCESS] Producer service deployed and ready
[SUCCESS] Consumer service deployed and ready

# Health Check Markers
[SUCCESS] ✓ PostgreSQL is accessible and ready
[SUCCESS] ✓ Kafka cluster is ready
[SUCCESS] ✓ Producer service is healthy
[SUCCESS] ✓ Consumer service is healthy

# Workflow Test Markers
[SUCCESS] ✓ Test message sent to producer
[SUCCESS] ✓ Consumer monitoring endpoint accessible
[SUCCESS] End-to-end workflow test completed
```

# =============================================================================
# MONITORING ENDPOINTS AVAILABLE AFTER STARTUP
# =============================================================================

## Producer Service (Port 8080)
```
Health Check:     GET  /actuator/health
Detailed Health:  GET  /actuator/health/readiness  
Metrics:          GET  /actuator/metrics
Prometheus:       GET  /actuator/prometheus
Info:             GET  /actuator/info
Stock Update API: POST /api/stock/update
```

## Consumer Service (Port 8081) 
```
Health Check:       GET  /api/consumer/actuator/health
Detailed Health:    GET  /api/consumer/actuator/health/readiness
Metrics:            GET  /api/consumer/actuator/metrics  
Prometheus:         GET  /api/consumer/actuator/prometheus
Processing Stats:   GET  /api/consumer/monitoring/statistics
Consumption Logs:   GET  /api/consumer/monitoring/logs
Error Analysis:     GET  /api/consumer/monitoring/errors/api
Performance Data:   GET  /api/consumer/monitoring/performance/slowest
```

## Kafka/AMQ Streams
```
Bootstrap Servers: kbnt-kafka-cluster-kafka-bootstrap:9092
Topic List:        kubectl get kafkatopics -n kbnt-system
Cluster Status:    kubectl get kafka kbnt-kafka-cluster -n kbnt-system
```

# =============================================================================
# TROUBLESHOOTING TIMEOUTS AND DELAYS
# =============================================================================

## Common Delays and Solutions

### 1. Kafka Cluster Taking Too Long (>5 minutes)
**Symptoms**: Strimzi operator pods not ready, Kafka pods in Pending state
**Solutions**:
- Check node resources: `kubectl describe nodes`
- Verify storage class availability
- Check Strimzi operator logs: `kubectl logs -n kbnt-system -l name=strimzi-cluster-operator`

### 2. Application Services Failing Health Checks
**Symptoms**: Services deploy but health checks fail
**Solutions**:
- Check application logs: `kubectl logs -n kbnt-system -l app=<service-name>`
- Verify Kafka connectivity from pods
- Check service discovery: `kubectl get endpoints -n kbnt-system`

### 3. End-to-End Test Failures
**Symptoms**: Messages sent but not processed, consumer statistics empty
**Solutions**:
- Verify topic creation: `kubectl get kafkatopics -n kbnt-system`
- Check consumer group status via Kafka tools
- Validate external API endpoints (if using real APIs)
- Review consumer service logs for processing errors

### 4. Database Connection Issues
**Symptoms**: Consumer service can't connect to PostgreSQL
**Solutions**:
- Check PostgreSQL pod status: `kubectl get pods -l app=kbnt-postgresql -n kbnt-system`
- Verify database credentials in secrets
- Test connection: `kubectl exec -it deployment/kbnt-postgresql -n kbnt-system -- psql -U kbnt_user -d kbnt_consumption_db`

## Performance Optimization for Faster Startup

### Development Environment (Faster startup)
```yaml
Kafka Replicas: 1 (instead of 3)
Topic Replicas: 1 (instead of 3)  
Service Replicas: 1 (instead of 2-3)
Resource Limits: Lower CPU/Memory
Health Check Intervals: Reduced
```

### Production Environment (Full resilience)
```yaml
Kafka Replicas: 3
Topic Replicas: 3
Service Replicas: 2-3
Resource Limits: Production values
Health Check Intervals: Standard
Persistent Storage: Enabled
```

# =============================================================================
# STARTUP COMMAND EXAMPLES
# =============================================================================

## Linux/Mac (Bash)
```bash
# Full startup
./scripts/start-complete-environment.sh startup

# With custom namespace
NAMESPACE=kbnt-dev ./scripts/start-complete-environment.sh startup

# Health checks only  
./scripts/start-complete-environment.sh health

# End-to-end test only
./scripts/start-complete-environment.sh test
```

## Windows (PowerShell)
```powershell
# Full startup
.\scripts\start-complete-environment.ps1 -Command startup

# With custom parameters
.\scripts\start-complete-environment.ps1 -Command startup -Namespace "kbnt-dev" -Environment "development"

# Health checks only
.\scripts\start-complete-environment.ps1 -Command health  

# End-to-end test only
.\scripts\start-complete-environment.ps1 -Command test
```

# =============================================================================
# LOG FILES LOCATIONS
# =============================================================================

## Kubernetes Pod Logs
```bash
# View all service logs
kubectl logs -n kbnt-system -l component=producer --tail=100 -f
kubectl logs -n kbnt-system -l component=consumer --tail=100 -f  
kubectl logs -n kbnt-system -l component=database --tail=100 -f

# Kafka cluster logs
kubectl logs -n kbnt-system -l strimzi.io/kind=Kafka --tail=100 -f
```

## Local Application Logs (if running locally)
```
Producer Service: logs/kbnt-stock-producer-service.log
Consumer Service: microservices/kbnt-stock-consumer-service/logs/kbnt-stock-consumer-service.log
```

## Startup Script Logs
```
Linux/Mac: /tmp/kbnt-startup.log (if redirected)
Windows: %TEMP%\kbnt-startup.log (if redirected)
```

# =============================================================================
# SUCCESS CRITERIA CHECKLIST
# =============================================================================

✅ **Infrastructure Ready**
- [ ] Kubernetes cluster accessible
- [ ] Namespace created and labeled
- [ ] PostgreSQL pod running and ready
- [ ] Kafka cluster status = Ready
- [ ] All 5 topics created successfully

✅ **Services Deployed**  
- [ ] Producer service pod running (2 replicas)
- [ ] Consumer service pod running (3 replicas)
- [ ] All services passing health checks
- [ ] Services registered in Kubernetes DNS

✅ **Connectivity Verified**
- [ ] Producer can connect to Kafka
- [ ] Consumer can connect to Kafka
- [ ] Consumer can connect to PostgreSQL
- [ ] Port forwarding works for all services

✅ **Functional Testing**
- [ ] Test message sent via Producer API
- [ ] Message appears in Kafka topic
- [ ] Consumer processes message successfully  
- [ ] Consumption log created in database
- [ ] Consumer monitoring API returns statistics

## Expected Final Output
```
[SUCCESS] Environment setup completed successfully!
[INFO] Producer Service: http://localhost:8080
[INFO] Consumer Service: http://localhost:8081/api/consumer  
[INFO] All 5 Kafka topics ready for message flow
[INFO] End-to-end workflow: Producer → Kafka → Consumer ✓
```

# =============================================================================
# ENVIRONMENT SPECIFIC CONFIGURATIONS
# =============================================================================

## Development (Minimum Resources)
- Total Memory: ~4GB
- Total CPU: ~2 cores
- Startup Time: 6-8 minutes
- Storage: Ephemeral (data lost on restart)

## Production (High Availability)  
- Total Memory: ~8GB
- Total CPU: ~4 cores
- Startup Time: 8-12 minutes  
- Storage: Persistent volumes
- Monitoring: Full observability stack

---
**Configuration Version**: 1.0.0  
**Last Updated**: 2025-08-30  
**Compatible With**: Kubernetes 1.24+, OpenShift 4.10+
