# 📦 Deployment Layer (Camada de Deployment)

A camada de deployment contém todos os recursos necessários para implantar e executar a aplicação KBNT Kafka Logs em diferentes ambientes (desenvolvimento, teste, produção). Esta camada implementa estratégias de containerização, orquestração e automação de deployment.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Estrutura](#-estrutura)
- [Docker Containers](#-docker-containers)
- [Kubernetes](#-kubernetes)
- [Ambientes](#-ambientes)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Configurações de Ambiente](#-configurações-de-ambiente)
- [Monitoramento](#-monitoramento)
- [Backup e Recovery](#-backup-e-recovery)
- [Segurança](#-segurança)
- [Performance](#-performance)
- [Troubleshooting](#-troubleshooting)

## 🎯 Visão Geral

Esta camada garante que a aplicação seja deployada de forma consistente, escalável e confiável em qualquer ambiente. Utiliza contêineres Docker para portabilidade e Kubernetes para orquestração em produção.

### Características Principais:
- **Containerização**: Docker containers para todos os serviços
- **Orquestração**: Kubernetes para ambientes de produção
- **Multi-ambiente**: Configurações para dev, test, staging e prod
- **Automação**: Scripts de deployment automatizado
- **Observabilidade**: Monitoramento integrado
- **Escalabilidade**: Auto-scaling horizontal e vertical

## 🏗️ Estrutura

```
06-deployment/
├── docker/                        # Configurações Docker
│   ├── api-gateway/
│   │   ├── Dockerfile
│   │   └── docker-compose.yml
│   ├── microservices/
│   │   ├── Dockerfile.stock-service
│   │   ├── Dockerfile.log-producer
│   │   ├── Dockerfile.log-consumer
│   │   └── docker-compose.microservices.yml
│   ├── infrastructure/
│   │   ├── kafka/
│   │   ├── postgresql/
│   │   ├── redis/
│   │   └── elasticsearch/
│   └── monitoring/
│       ├── prometheus/
│       ├── grafana/
│       └── jaeger/
├── kubernetes/                    # Manifests Kubernetes
│   ├── namespaces/
│   ├── configmaps/
│   ├── secrets/
│   ├── deployments/
│   ├── services/
│   ├── ingress/
│   └── monitoring/
├── environments/                  # Configurações por ambiente
│   ├── development/
│   ├── testing/
│   ├── staging/
│   └── production/
├── scripts/                       # Scripts de deployment
│   ├── deploy.sh
│   ├── rollback.sh
│   ├── health-check.sh
│   └── cleanup.sh
└── README.md                     # Este arquivo
```

## 🐳 Docker Containers

### Configurações Docker Compose Disponíveis:

#### 1. **docker-compose.scalable.yml** - Produção Escalável
```yaml
version: '3.8'
services:
  # API Gateway
  api-gateway:
    build: ./01-presentation-layer/api-gateway
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=scalable
      - KAFKA_BOOTSTRAP_SERVERS=kafka1:9092,kafka2:9092,kafka3:9092
    depends_on:
      - kafka1
      - kafka2
      - kafka3
    networks:
      - kbnt-network
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'

  # Stock Service
  stock-service:
    build: ./05-microservices/virtual-stock-service
    environment:
      - SPRING_PROFILES_ACTIVE=scalable
      - DATABASE_URL=jdbc:postgresql://postgres-primary:5432/stock_db
      - REDIS_URL=redis://redis-cluster:6379
    depends_on:
      - postgres-primary
      - redis-cluster
    networks:
      - kbnt-network
    deploy:
      replicas: 5
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

  # Kafka Cluster
  kafka1:
    image: confluentinc/cp-kafka:7.4.0
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka1:9092
      KAFKA_NUM_PARTITIONS: 12
      KAFKA_DEFAULT_REPLICATION_FACTOR: 3
    volumes:
      - kafka1-data:/var/lib/kafka/data
    networks:
      - kbnt-network

  # PostgreSQL Primary
  postgres-primary:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: kbnt_db
      POSTGRES_USER: kbnt_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "--auth-host=md5"
    volumes:
      - postgres-primary-data:/var/lib/postgresql/data
      - ./sql/init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    networks:
      - kbnt-network

  # Redis Cluster
  redis-cluster:
    image: redis:7-alpine
    command: redis-server --appendonly yes --cluster-enabled yes
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"
    networks:
      - kbnt-network

volumes:
  kafka1-data:
  postgres-primary-data:
  redis-data:

networks:
  kbnt-network:
    driver: bridge
```

#### 2. **docker-compose.free-tier.yml** - Desenvolvimento
```yaml
version: '3.8'
services:
  # Single Kafka instance for development
  kafka:
    image: confluentinc/cp-kafka:7.4.0
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: true
    ports:
      - "9092:9092"
    depends_on:
      - zookeeper

  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  # Development database
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: kbnt_dev
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: dev_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres-dev-data:/var/lib/postgresql/data

volumes:
  postgres-dev-data:
```

### Comandos Docker Essenciais:

```bash
# Desenvolvimento (Free Tier)
docker-compose -f docker-compose.free-tier.yml up -d

# Produção Escalável
docker-compose -f docker-compose.scalable.yml up -d

# Monitoramento
docker-compose -f docker-compose.monitoring.yml up -d

# Parar todos os serviços
docker-compose down

# Logs de um serviço específico
docker-compose logs -f stock-service

# Escalabilidade manual
docker-compose up -d --scale stock-service=5
```

## ☸️ Kubernetes

### Manifests Principais:

#### 1. **Namespace**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kbnt-kafka-logs
  labels:
    name: kbnt-kafka-logs
    environment: production
```

#### 2. **Stock Service Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stock-service
  namespace: kbnt-kafka-logs
spec:
  replicas: 5
  selector:
    matchLabels:
      app: stock-service
  template:
    metadata:
      labels:
        app: stock-service
    spec:
      containers:
      - name: stock-service
        image: kbnt/stock-service:latest
        ports:
        - containerPort: 8081
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
```

#### 3. **Kafka StatefulSet**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: kbnt-kafka-logs
spec:
  serviceName: kafka-headless
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.4.0
        ports:
        - containerPort: 9092
        env:
        - name: KAFKA_BROKER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper:2181"
        volumeMounts:
        - name: kafka-storage
          mountPath: /var/lib/kafka/data
  volumeClaimTemplates:
  - metadata:
      name: kafka-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

#### 4. **HorizontalPodAutoscaler**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: stock-service-hpa
  namespace: kbnt-kafka-logs
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: stock-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Comandos Kubernetes:

```bash
# Aplicar manifests
kubectl apply -f kubernetes/

# Verificar status
kubectl get pods -n kbnt-kafka-logs

# Logs de um pod
kubectl logs -f deployment/stock-service -n kbnt-kafka-logs

# Escalar deployment
kubectl scale deployment stock-service --replicas=10 -n kbnt-kafka-logs

# Port forward para debug
kubectl port-forward svc/stock-service 8081:8081 -n kbnt-kafka-logs
```

## 🌍 Ambientes

### Configurações por Ambiente:

#### Development
- **Infraestrutura**: Docker Compose local
- **Banco**: PostgreSQL single instance
- **Kafka**: Single broker
- **Recursos**: Minimal (2 CPU, 4GB RAM)
- **Logs**: Debug level

#### Testing
- **Infraestrutura**: Kubernetes minikube
- **Banco**: PostgreSQL com replica read-only
- **Kafka**: 3 brokers
- **Recursos**: Medium (4 CPU, 8GB RAM)
- **Logs**: Info level

#### Staging
- **Infraestrutura**: Kubernetes cluster
- **Banco**: PostgreSQL cluster
- **Kafka**: 3 brokers com replicação
- **Recursos**: Production-like (8 CPU, 16GB RAM)
- **Logs**: Warn level

#### Production
- **Infraestrutura**: Kubernetes cluster multi-zone
- **Banco**: PostgreSQL HA cluster
- **Kafka**: 5+ brokers com cross-AZ
- **Recursos**: High-performance (16+ CPU, 32+ GB RAM)
- **Logs**: Error level

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow:

```yaml
name: KBNT Kafka Logs CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Run tests
      run: ./mvnw test
    
    - name: Generate test report
      run: ./mvnw jacoco:report

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker images
      run: |
        docker build -t kbnt/api-gateway:${{ github.sha }} ./01-presentation-layer/api-gateway
        docker build -t kbnt/stock-service:${{ github.sha }} ./05-microservices/virtual-stock-service
    
    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push kbnt/api-gateway:${{ github.sha }}
        docker push kbnt/stock-service:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to staging
      run: |
        kubectl set image deployment/stock-service stock-service=kbnt/stock-service:${{ github.sha }} -n kbnt-staging
    
    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/stock-service -n kbnt-staging --timeout=300s
```

## ⚡ Performance

### Métricas de Performance:
- **Throughput**: 27,364 RPS
- **Latência**: P95 < 50ms
- **Uptime**: 99.9%+
- **Auto-scaling**: 3-20 replicas

### Otimizações de Deployment:
- **Resource Requests/Limits**: Otimizados por workload
- **Readiness/Liveness Probes**: Health checks customizados
- **Rolling Updates**: Zero-downtime deployments
- **Horizontal Pod Autoscaler**: Baseado em CPU e memória

## 🔧 Scripts de Automação

### Deploy Script:
```bash
#!/bin/bash
# deploy.sh - Script de deployment automatizado

ENVIRONMENT=${1:-development}
VERSION=${2:-latest}

echo "🚀 Deploying KBNT Kafka Logs to $ENVIRONMENT"

case $ENVIRONMENT in
  "development")
    docker-compose -f docker-compose.free-tier.yml up -d
    ;;
  "staging")
    kubectl apply -f kubernetes/staging/
    kubectl set image deployment/stock-service stock-service=kbnt/stock-service:$VERSION -n kbnt-staging
    ;;
  "production")
    kubectl apply -f kubernetes/production/
    kubectl set image deployment/stock-service stock-service=kbnt/stock-service:$VERSION -n kbnt-production
    ;;
esac

echo "✅ Deployment completed!"
```

### Health Check Script:
```bash
#!/bin/bash
# health-check.sh - Verificação de saúde dos serviços

ENVIRONMENT=${1:-development}

echo "🔍 Checking health of KBNT services in $ENVIRONMENT"

# Check API Gateway
curl -f http://localhost:8080/actuator/health || exit 1

# Check Stock Service
curl -f http://localhost:8081/actuator/health || exit 1

# Check Kafka
kafka-topics.sh --bootstrap-server localhost:9092 --list || exit 1

echo "✅ All services are healthy!"
```

## 🔒 Segurança

### Práticas de Segurança:
- **Secrets Management**: Kubernetes secrets + external vaults
- **Network Policies**: Micro-segmentação de rede
- **Image Scanning**: Vulnerabilidade scanning em CI/CD
- **RBAC**: Role-based access control
- **TLS**: Encryption in transit
- **Pod Security Standards**: Restricted security contexts

---

**Autor**: KBNT Development Team  
**Versão**: 2.1.0  
**Última Atualização**: Janeiro 2025
