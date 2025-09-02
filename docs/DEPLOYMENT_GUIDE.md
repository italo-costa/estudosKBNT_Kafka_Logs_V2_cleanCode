# 🚀 Independent Deployment Guide

This guide covers the deployment of Kafka topics and microservices independently, allowing flexible and modular deployment strategies.

## 📋 Overview

The refactored architecture supports:
- **Independent Topic Deployment**: Kafka topics can be deployed separately from microservices
- **Standalone Microservices**: Services can start with or without pre-existing topics
- **Graceful Degradation**: Services operate in degraded mode when topics are unavailable
- **Auto-Recovery**: Automatic topic creation and connection recovery

## 🏗️ Architecture Components

### 1. Kafka Topics (`kafka/topics/`)
- `application-logs/` - Application event logs
- `error-logs/` - Error and exception logs  
- `audit-logs/` - Security and audit events
- `financial-logs/` - Financial transaction logs

### 2. Microservices (`microservices/`)
- `log-producer-service/` - Produces logs to Kafka topics
- `log-consumer-service/` - Consumes and processes logs

### 3. Docker Configurations (`docker/`)
- `docker-compose.infrastructure.yml` - Full Kafka infrastructure
- `docker-compose.microservices.yml` - Lightweight microservices deployment
- `docker-compose.topics.yml` - Topic deployment only

## 🚀 Deployment Strategies

### Strategy 1: Full Infrastructure Deployment
Deploy everything together (traditional approach):

```powershell
# Start full infrastructure
cd docker
docker-compose -f docker-compose.infrastructure.yml up -d

# Deploy topics
cd ../kafka/topics
kubectl apply -f application-logs/
kubectl apply -f error-logs/
kubectl apply -f audit-logs/
kubectl apply -f financial-logs/

# Start microservices
cd ../../docker
docker-compose -f docker-compose.microservices.yml up -d
```

### Strategy 2: Independent Topic Deployment
Deploy topics first, microservices later:

```powershell
# 1. Deploy topics only
cd kafka/topics
kubectl apply -f application-logs/topic-config.yaml
kubectl apply -f error-logs/topic-config.yaml
kubectl apply -f audit-logs/topic-config.yaml
kubectl apply -f financial-logs/topic-config.yaml

# 2. Verify topics
kubectl get kafkatopics

# 3. Deploy microservices (they will connect to existing topics)
cd ../../docker
docker-compose -f docker-compose.microservices.yml up -d
```

### Strategy 3: Microservices-First Deployment
Start microservices without pre-existing topics:

```powershell
# 1. Start microservices with auto-topic creation
cd docker
docker-compose -f docker-compose.microservices.yml up -d

# Topics will be automatically created by the services
# Check logs to confirm topic creation:
docker-compose logs log-producer-service
docker-compose logs log-consumer-service
```

### Strategy 4: Gradual Rollout
Deploy components incrementally:

```powershell
# 1. Start minimal Kafka infrastructure
docker-compose -f docker-compose.infrastructure.yml up kafka zookeeper -d

# 2. Deploy critical topics first
kubectl apply -f kafka/topics/error-logs/
kubectl apply -f kafka/topics/audit-logs/

# 3. Start producer service
docker-compose -f docker-compose.microservices.yml up log-producer-service -d

# 4. Add remaining topics
kubectl apply -f kafka/topics/application-logs/
kubectl apply -f kafka/topics/financial-logs/

# 5. Start consumer service
docker-compose -f docker-compose.microservices.yml up log-consumer-service -d
```

## 🔧 Configuration Options

### Environment Variables

#### Topic Configuration
```bash
# Topic settings
APP_KAFKA_TOPICS_PARTITIONS=3
APP_KAFKA_TOPICS_REPLICATION_FACTOR=1
APP_KAFKA_TOPICS_APPLICATION_LOGS=application-logs
APP_KAFKA_TOPICS_ERROR_LOGS=error-logs
APP_KAFKA_TOPICS_AUDIT_LOGS=audit-logs
APP_KAFKA_TOPICS_FINANCIAL_LOGS=financial-logs

# Independence settings
APP_INDEPENDENCE_TOPIC_CREATION_TIMEOUT=30000
APP_INDEPENDENCE_REQUIRE_ALL_TOPICS=false
APP_INDEPENDENCE_DEGRADED_MODE_ENABLED=true
```

#### Kafka Connection
```bash
# Kafka connectivity
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
SPRING_KAFKA_CLIENT_ID=log-service
KAFKA_AUTO_CREATE_TOPICS_ENABLE=true

# Producer settings
SPRING_KAFKA_PRODUCER_RETRIES=3
SPRING_KAFKA_PRODUCER_BATCH_SIZE=16384
SPRING_KAFKA_PRODUCER_LINGER_MS=5

# Consumer settings
SPRING_KAFKA_CONSUMER_GROUP_ID=log-consumer-group
SPRING_KAFKA_CONSUMER_AUTO_OFFSET_RESET=earliest
SPRING_KAFKA_CONSUMER_ENABLE_AUTO_COMMIT=true
```

## 🔍 Monitoring and Health Checks

### Health Endpoints
- Producer Service: `http://localhost:8080/actuator/health`
- Consumer Service: `http://localhost:8081/actuator/health`

### Health Status Types
- **UP**: All topics available, full functionality
- **DEGRADED**: Partial topic availability, limited functionality
- **DOWN**: Kafka unavailable or critical topics missing

### Monitoring Commands
```powershell
# Check service health
curl http://localhost:8080/actuator/health/kafkaIndependentHealthIndicator

# Check topic status
kubectl get kafkatopics
kubectl describe kafkatopic application-logs

# View service logs
docker-compose logs -f log-producer-service
docker-compose logs -f log-consumer-service

# Monitor Kafka
docker exec -it kafka kafka-topics.sh --bootstrap-server localhost:9092 --list
```

## 🛠️ Troubleshooting

### Common Issues

#### Topics Not Created
```powershell
# Check AdminClient connectivity
docker exec -it log-producer-service curl http://localhost:8080/actuator/health

# Manually create topic
docker exec -it kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --topic application-logs --partitions 3 --replication-factor 1
```

#### Service Startup Timeout
```powershell
# Increase timeout in docker-compose
environment:
  - APP_INDEPENDENCE_TOPIC_CREATION_TIMEOUT=60000

# Or disable auto-creation
environment:
  - KAFKA_AUTO_CREATE_TOPICS_ENABLE=false
```

#### Connection Issues
```powershell
# Check network connectivity
docker-compose exec log-producer-service ping kafka

# Verify bootstrap servers
docker-compose logs kafka | grep "started (kafka.server.KafkaServer)"
```

### Recovery Procedures

#### Restart Single Service
```powershell
docker-compose restart log-producer-service
```

#### Reset Consumer Offsets
```powershell
docker exec -it kafka kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group log-consumer-group --reset-offsets --to-earliest --all-topics --execute
```

#### Clean Restart
```powershell
# Stop all services
docker-compose down

# Remove volumes (⚠️ DATA LOSS)
docker-compose down -v

# Start fresh
docker-compose up -d
```

## 📚 Advanced Configuration

### Custom Topic Configuration
Edit `kafka/topics/*/topic-config.yaml`:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: custom-logs
spec:
  partitions: 6
  replicas: 2
  config:
    retention.ms: 1209600000  # 14 days
    compression.type: "lz4"
    max.message.bytes: 2097152  # 2MB
```

### Service Configuration
Edit `microservices/*/src/main/resources/application.yml`:

```yaml
app:
  independence:
    topic-creation-timeout: 45000
    require-all-topics: true
    degraded-mode-enabled: false
  kafka:
    topics:
      partitions: 6
      replication-factor: 2
```

## 🎯 Best Practices

1. **Monitor Health Endpoints**: Always check service health after deployment
2. **Gradual Rollouts**: Deploy topics before services for zero-downtime updates
3. **Resource Limits**: Set appropriate memory/CPU limits in Docker Compose
4. **Backup Strategy**: Regular backup of Kafka data and configurations
5. **Testing**: Test degraded mode scenarios in staging environment

## 📞 Support

- Check logs: `docker-compose logs <service-name>`
- Health status: `curl http://localhost:<port>/actuator/health`
- Kafka UI: Access Kafka management interface at configured port
- Documentation: Refer to `docs/DIAGRAMAS_ARQUITETURA_COMPLETOS.md` for architecture details
