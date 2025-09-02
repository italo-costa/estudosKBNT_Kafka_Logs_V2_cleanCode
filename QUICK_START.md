# 🎯 Quick Reference Guide

## 🚀 **One-Command Deployment**

### 🐳 **Docker Compose (Development)**
```bash
# Start everything
docker-compose up -d

# Test the system
curl -X POST http://localhost:8081/api/v1/logs \
  -H "Content-Type: application/json" \
  -d '{"level":"INFO","message":"Test log","service":"quick-test","requestId":"123e4567-e89b-12d3-a456-426614174000"}'
```

### ☸️ **Kubernetes (Production)**
```bash
# Deploy infrastructure
kubectl apply -f kubernetes/
kubectl apply -f hybrid-deployment/

# Wait for services
kubectl wait --for=condition=ready pod -l app=kafka -n kafka --timeout=300s

# Test from pod
kubectl run test-pod --image=curlimages/curl --rm -it -- \
  curl -X POST http://log-producer-service:8081/api/v1/logs \
  -H "Content-Type: application/json" \
  -d '{"level":"INFO","message":"K8s test","service":"kubernetes","requestId":"123e4567-e89b-12d3-a456-426614174000"}'
```

---

## 📊 **Architecture at a Glance**

### 🏗️ **Hexagonal Architecture Benefits**

| ✅ **Achieved** | 🎯 **Benefit** |
|-----------------|----------------|
| **Zero External Dependencies in Domain** | Pure business logic testing |
| **Swappable Infrastructure** | Kafka ↔ RabbitMQ in minutes |
| **Clean Layer Separation** | Independent team development |
| **Comprehensive Metrics** | Production-ready observability |

### 🔄 **Message Flow (30 seconds)**

```
HTTP Log → Validation → Routing → Kafka → Consumer → External API → Metrics
   ↓          ↓          ↓        ↓       ↓         ↓            ↓
  REST    Business   Smart    AMQ    Async    Integration   Prometheus
 Layer      Rules   Topics  Streams  Process     Layer       Dashboard
```

---

## 📈 **Monitoring Endpoints**

### 🎯 **Health Checks**

| Service | Endpoint | Status |
|---------|----------|--------|
| **Producer** | http://localhost:8081/actuator/health | ✅ Ready |
| **Consumer** | http://localhost:8082/actuator/health | 🚧 In Progress |
| **Kafka** | kafka-cluster-kafka-bootstrap.kafka.svc:9092 | ✅ Ready |

### 📊 **Metrics**

| Metric Type | Endpoint | Description |
|-------------|----------|-------------|
| **Application** | http://localhost:8081/actuator/metrics | Spring Boot metrics |
| **Prometheus** | http://localhost:8081/actuator/prometheus | Prometheus format |
| **Custom** | http://localhost:8081/actuator/metrics/logs.published.total | Business metrics |

---

## 🧪 **Testing Commands**

### 🔧 **Development Testing**

```bash
# Unit tests (Domain layer)
./mvnw test -Dtest="*DomainTest"

# Integration tests (Use Cases)
./mvnw test -Dtest="*UseCaseTest"

# Infrastructure tests (Adapters)
./mvnw test -Dtest="*AdapterTest"
```

### 📋 **Production Testing**

```bash
# Load test (100 logs/second)
for i in {1..100}; do
  curl -X POST http://localhost:8081/api/v1/logs \
    -H "Content-Type: application/json" \
    -d "{\"level\":\"INFO\",\"message\":\"Load test $i\",\"service\":\"load-test\",\"requestId\":\"$(uuidgen)\"}" &
done

# Check metrics
curl http://localhost:8081/actuator/metrics/logs.published.total
```

---

## 🔧 **Troubleshooting**

### ❌ **Common Issues**

| Problem | Solution | Command |
|---------|----------|---------|
| **Kafka not ready** | Wait for bootstrap | `kubectl logs kafka-cluster-kafka-0 -n kafka` |
| **Port conflict** | Change ports | Edit `application.yml` |
| **Memory issues** | Increase limits | Edit `docker-compose.yml` |

### 🔍 **Debug Commands**

```bash
# Check Kafka topics
kubectl exec -it kafka-cluster-kafka-0 -n kafka -- \
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# View Kafka messages
kubectl exec -it kafka-cluster-kafka-0 -n kafka -- \
  /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic application-logs --from-beginning

# Producer service logs
kubectl logs -f deployment/log-producer-service -n kafka
```

---

## 📚 **Next Steps**

### 🎯 **Learning Path**

1. **📖 Read Architecture**: [Hexagonal Architecture Guide](docs/ARQUITETURA_HEXAGONAL.md)
2. **🔄 Study Workflow**: [Integration Workflow](docs/WORKFLOW_INTEGRACAO.md)
3. **💻 Try Examples**: Run the quick start commands above
4. **🧪 Write Tests**: Follow the testing strategy
5. **🚀 Deploy Production**: Use Kubernetes deployment

### 🛠️ **Customization**

- **Add New Log Types**: Extend `LogLevel` value object
- **New Routing Rules**: Modify `LogRoutingService`
- **External APIs**: Implement `ExternalApiPort` for Consumer
- **Custom Metrics**: Add to `MetricsPort` implementations
- **New Validations**: Extend `LogValidationService`

---

## 🎉 **Success Indicators**

✅ **You're Ready When:**

- [ ] All services show healthy status
- [ ] Logs flow from Producer → Kafka → Consumer
- [ ] Metrics appear in Prometheus format
- [ ] External API integration works
- [ ] Tests pass at all layers
- [ ] Documentation makes sense to your team

**🚀 Welcome to Enterprise-Grade Microservices!**
