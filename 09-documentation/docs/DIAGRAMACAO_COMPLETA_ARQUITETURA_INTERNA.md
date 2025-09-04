# DIAGRAMAÇÃO COMPLETA DA ARQUITETURA KBNT - KAFKA LOGS
## Documentação Técnica Interna - NÃO PUBLICAR NO GITHUB

---

## 🏗️ VISÃO GERAL DA ARQUITETURA IMPLEMENTADA

```mermaid
graph TB
    subgraph "AMBIENTE LOCAL DE DESENVOLVIMENTO"
        subgraph "APLICAÇÕES SIMPLIFICADAS"
            SA[SimpleStockApplication<br/>Spring Boot Monolito<br/>Porta: 8080]
            TE[TestEnvironmentApplication<br/>Ambiente de Testes<br/>Porta: 8081]
        end
        
        subgraph "SCRIPTS DE AUTOMAÇÃO"
            WF[complete-validation-workflow.ps1<br/>Workflow 300 Mensagens<br/>Score: 92/100]
            ST[simple-real-test-300.ps1<br/>Teste de Tráfego<br/>Performance: 29.84 req/s]
        end
    end

    subgraph "ARQUITETURA HEXAGONAL (MICROSERVIÇOS)"
        subgraph "DOMAIN LAYER"
            DM[Domain Models<br/>Stock.java<br/>LogMessage.java<br/>StockUpdateMessage.java]
            UC[Use Cases<br/>StockManagementUseCase<br/>LogProcessingUseCase]
            DP[Domain Ports<br/>Input/Output Interfaces]
        end
        
        subgraph "APPLICATION LAYER"
            AS[Application Services<br/>StockService.java<br/>LogAnalyticsService.java]
        end
        
        subgraph "INFRASTRUCTURE LAYER"
            subgraph "INPUT ADAPTERS"
                RC[REST Controllers<br/>StockController<br/>LogController]
                KC[Kafka Consumers<br/>@KafkaListener]
            end
            
            subgraph "OUTPUT ADAPTERS"
                KP[Kafka Producers<br/>LogProducerService]
                DB[Database Adapters<br/>PostgreSQL<br/>Redis Cache]
                EX[External Services<br/>HTTP Clients]
            end
        end
    end

    subgraph "INFRAESTRUTURA DE DADOS"
        subgraph "KAFKA ECOSYSTEM"
            ZK[Zookeeper<br/>Porta: 2181<br/>Coordenação de Cluster]
            KB[Kafka Brokers<br/>Porta: 9092<br/>3 Réplicas]
            
            subgraph "TÓPICOS KAFKA"
                T1[application-logs<br/>3 partições, 2 réplicas<br/>Retenção: 3 dias]
                T2[error-logs<br/>3 partições, 2 réplicas<br/>Retenção: 7 dias]
                T3[audit-logs<br/>2 partições, 2 réplicas<br/>Retenção: 30 dias]
                T4[financial-logs<br/>3 partições, 2 réplicas<br/>Retenção: 90 dias]
                T5[stock-updates<br/>Para testes de tráfego]
            end
        end
        
        subgraph "BANCOS DE DADOS"
            PG[PostgreSQL<br/>Porta: 5432<br/>Database: loganalytics<br/>User: loguser]
            RD[Redis Cache<br/>Porta: 6379<br/>Cache de Performance]
            H2[H2 Database<br/>Testes In-Memory]
        end
    end

    subgraph "MICROSERVIÇOS IMPLEMENTADOS"
        subgraph "PRODUCER SERVICES"
            LPS[log-producer-service<br/>Porta: 8081<br/>Produz logs para Kafka]
            VSS[virtual-stock-service<br/>Porta: 8080<br/>API de Ações Virtuais]
        end
        
        subgraph "CONSUMER SERVICES"  
            LCS[log-consumer-service<br/>Porta: 8082<br/>Processa logs do Kafka]
            SCS[stock-consumer-service<br/>Porta: 8083<br/>Processa atualizações de ações]
        end
        
        subgraph "ANALYTICS SERVICES"
            LAS[log-analytics-service<br/>Porta: 8083<br/>Análise de logs<br/>+ Redis Cache]
        end
        
        subgraph "GATEWAY"
            AG[api-gateway<br/>Porta: 8080<br/>Roteamento e Load Balance]
        end
    end

    %% Conexões Principais
    SA --> WF
    WF --> ST
    
    RC --> AS
    AS --> UC
    UC --> DM
    AS --> KP
    AS --> DB
    KC --> AS
    
    LPS --> KB
    KB --> LCS
    KB --> SCS
    LCS --> PG
    LAS --> RD
    
    KB --> T1
    KB --> T2  
    KB --> T3
    KB --> T4
    KB --> T5
    
    ZK --> KB
    
    AG --> LPS
    AG --> LAS
```

---

## 🐳 CONTAINERIZAÇÃO E ORQUESTRAÇÃO

### Docker Compose - Ambiente Local

```mermaid
graph TB
    subgraph "docker-compose.yml - MICROSERVICES"
        subgraph "Infrastructure Services"
            DC_PG[postgres:15-alpine<br/>Container: postgres-logs<br/>Porta: 5432<br/>Volume: postgres-data]
            DC_RD[redis:7-alpine<br/>Container: redis-logs<br/>Porta: 6379<br/>Health Check: redis-cli ping]
            DC_ZK[cp-zookeeper:7.4.0<br/>Extends: ../docker/docker-compose.yml]
            DC_KF[cp-kafka:7.4.0<br/>Extends: ../docker/docker-compose.yml]
        end
        
        subgraph "Application Services"
            DC_LPS[log-producer-service<br/>Build: ./log-producer-service<br/>Porta: 8081, 9081<br/>Profile: docker]
            DC_LCS[log-consumer-service<br/>Build: ./log-consumer-service<br/>Porta: 8082, 9082<br/>Profile: docker]
            DC_LAS[log-analytics-service<br/>Build: ./log-analytics-service<br/>Porta: 8083, 9083<br/>Profile: docker]
            DC_AG[api-gateway<br/>Build: ./api-gateway<br/>Porta: 8080, 9080<br/>Profile: docker]
        end
        
        subgraph "Health Checks"
            HC1[curl -f /actuator/health<br/>Interval: 30s<br/>Timeout: 10s<br/>Retries: 5]
            HC2[pg_isready<br/>Database Health]
        end
    end

    DC_ZK --> DC_KF
    DC_KF --> DC_LPS
    DC_KF --> DC_LCS
    DC_PG --> DC_LCS
    DC_PG --> DC_LAS
    DC_RD --> DC_LAS
    DC_LPS --> DC_AG
    DC_LAS --> DC_AG
    
    DC_LPS --> HC1
    DC_LCS --> HC1
    DC_LAS --> HC1
    DC_AG --> HC1
    DC_PG --> HC2
```

### Docker Compose - Simulação Local

```mermaid
graph LR
    subgraph "simulation/docker-compose.local.yml"
        subgraph "Kafka Infrastructure"
            SIM_ZK[zookeeper<br/>cp-zookeeper:7.4.0<br/>Container: kbnt-zookeeper<br/>Porta: 2181]
            SIM_KF[kafka<br/>cp-kafka:7.4.0<br/>Container: kbnt-kafka<br/>Porta: 9092]
            SIM_UI[kafka-ui<br/>provectuslabs/kafka-ui<br/>Container: kbnt-kafka-ui<br/>Monitoramento]
        end
        
        subgraph "Volumes"
            V1[zookeeper-data<br/>zookeeper-logs]
            V2[kafka-data]
        end
        
        subgraph "Network"
            NET[kbnt-network<br/>Isolated Network]
        end
    end
    
    SIM_ZK --> SIM_KF
    SIM_KF --> SIM_UI
    V1 --> SIM_ZK
    V2 --> SIM_KF
    NET --> SIM_ZK
    NET --> SIM_KF
    NET --> SIM_UI
```

---

## ☸️ KUBERNETES - ORQUESTRAÇÃO AVANÇADA

### Kafka Cluster no Kubernetes

```mermaid
graph TB
    subgraph "KUBERNETES NAMESPACE: kafka"
        subgraph "Strimzi Kafka Operator"
            SO[Strimzi Operator<br/>Kafka Management<br/>Custom Resources]
        end
        
        subgraph "Kafka Cluster"
            KC[Kafka Custom Resource<br/>apiVersion: kafka.strimzi.io/v1beta2<br/>kind: Kafka<br/>name: kafka-cluster]
            
            subgraph "Kafka Brokers"
                K1[kafka-cluster-kafka-0<br/>Version: 3.4.0<br/>Replica: 1/3]
                K2[kafka-cluster-kafka-1<br/>Version: 3.4.0<br/>Replica: 2/3] 
                K3[kafka-cluster-kafka-2<br/>Version: 3.4.0<br/>Replica: 3/3]
            end
            
            subgraph "Zookeeper Cluster"
                Z1[kafka-cluster-zookeeper-0<br/>Replica: 1/3]
                Z2[kafka-cluster-zookeeper-1<br/>Replica: 2/3]
                Z3[kafka-cluster-zookeeper-2<br/>Replica: 3/3]
            end
        end
        
        subgraph "Storage"
            subgraph "Persistent Volumes"
                PV1[kafka-storage-0<br/>100Gi JBOD<br/>deleteClaim: false]
                PV2[kafka-storage-1<br/>100Gi JBOD<br/>deleteClaim: false]
                PV3[kafka-storage-2<br/>100Gi JBOD<br/>deleteClaim: false]
            end
        end
        
        subgraph "Network Configuration"
            subgraph "Listeners"
                L1[plain: 9092<br/>type: internal<br/>tls: false]
                L2[tls: 9093<br/>type: internal<br/>tls: true]
            end
        end
    end
    
    SO --> KC
    KC --> K1
    KC --> K2
    KC --> K3
    KC --> Z1
    KC --> Z2
    KC --> Z3
    
    K1 --> PV1
    K2 --> PV2  
    K3 --> PV3
    
    K1 --> L1
    K2 --> L1
    K3 --> L1
    K1 --> L2
    K2 --> L2
    K3 --> L2
```

### Microserviços no Kubernetes

```mermaid
graph TB
    subgraph "KUBERNETES NAMESPACE: microservices"
        subgraph "ConfigMaps & Secrets"
            CM1[kafka-external-config<br/>Bootstrap servers<br/>Security protocol<br/>Consumer groups]
            S1[kafka-external-credentials<br/>kafka-username<br/>kafka-password<br/>truststore.jks]
        end
        
        subgraph "Deployments"
            subgraph "Producer Services"
                DP1[log-producer-service<br/>Replicas: 2<br/>Image: kbnt/log-producer-service:1.0.0<br/>Port: 8081]
            end
            
            subgraph "Consumer Services"
                DC1[log-consumer-service<br/>Replicas: 2<br/>Image: kbnt/log-consumer-service:1.0.0<br/>Port: 8082]
                DC2[stock-consumer-service<br/>Replicas: 1<br/>Image: kbnt/stock-consumer-service:1.0.0<br/>Port: 8083]
            end
        end
        
        subgraph "Services"
            SVC1[log-producer-service<br/>ClusterIP<br/>Port: 8081]
            SVC2[log-consumer-service<br/>ClusterIP<br/>Port: 8082]  
            SVC3[stock-consumer-service<br/>ClusterIP<br/>Port: 8083]
        end
        
        subgraph "Ingress"
            ING[microservices-ingress<br/>nginx/traefik<br/>Host: microservices.local]
        end
        
        subgraph "Volume Mounts"
            VM1[/etc/kafka<br/>kafka-truststore<br/>readOnly: true]
        end
    end
    
    CM1 --> DP1
    CM1 --> DC1
    CM1 --> DC2
    S1 --> DP1
    S1 --> DC1
    S1 --> DC2
    
    DP1 --> SVC1
    DC1 --> SVC2
    DC2 --> SVC3
    
    SVC1 --> ING
    SVC2 --> ING
    SVC3 --> ING
    
    VM1 --> DP1
    VM1 --> DC1
    VM1 --> DC2
```

---

## 🔗 CONFIGURAÇÃO HÍBRIDA - RED HAT AMQ STREAMS

### Conexão Local + Red Hat AMQ Streams

```mermaid
graph TB
    subgraph "AMBIENTE RED HAT OPENSHIFT"
        subgraph "AMQ Streams Cluster"
            RH_OP[AMQ Streams Operator<br/>Red Hat Supported]
            RH_KC[Kafka Cluster<br/>kafka-cluster.redhat-env.com:9092<br/>SASL_SSL + SCRAM-SHA-512]
            
            subgraph "Topics Red Hat"
                RH_T1[application-logs<br/>Partitions: 3, Replicas: 3]
                RH_T2[error-logs<br/>Partitions: 3, Replicas: 3]
                RH_T3[audit-logs<br/>Partitions: 3, Replicas: 3]
            end
            
            subgraph "Security"
                RH_SEC[SCRAM-SHA-512 Auth<br/>TLS Encryption<br/>Certificate: ca.crt]
            end
        end
    end
    
    subgraph "AMBIENTE LOCAL KUBERNETES"
        subgraph "Hybrid Configuration"
            H_CM[ConfigMap: kafka-external-config<br/>bootstrap-servers: kafka-cluster.redhat-env.com:9092<br/>security-protocol: SASL_SSL<br/>sasl-mechanism: SCRAM-SHA-512]
            
            H_SEC[Secret: kafka-external-credentials<br/>kafka-username: microservices-user<br/>kafka-password: encrypted<br/>truststore.jks: base64-encoded]
        end
        
        subgraph "Local Microservices"
            H_PROD[log-producer-service<br/>Profile: hybrid<br/>External Kafka Connection]
            H_CONS[log-consumer-service<br/>Profile: hybrid<br/>External Kafka Connection]
        end
        
        subgraph "Network Security"
            H_NP[NetworkPolicy<br/>kafka-external-access<br/>Egress: TCP 9092, 443]
        end
    end
    
    subgraph "CONECTIVIDADE"
        subgraph "Opção A: VPN/Túnel"
            VPN[VPN Corporativa<br/>Acesso seguro<br/>kafka-cluster.company.com]
        end
        
        subgraph "Opção B: Exposição Pública"
            LB[LoadBalancer/NodePort<br/>IP Público<br/>203.0.113.100:9092]
        end
    end
    
    RH_OP --> RH_KC
    RH_KC --> RH_T1
    RH_KC --> RH_T2  
    RH_KC --> RH_T3
    RH_KC --> RH_SEC
    
    H_CM --> H_PROD
    H_CM --> H_CONS
    H_SEC --> H_PROD
    H_SEC --> H_CONS
    H_NP --> H_PROD
    H_NP --> H_CONS
    
    VPN --> RH_KC
    LB --> RH_KC
    H_PROD --> VPN
    H_PROD --> LB
    H_CONS --> VPN
    H_CONS --> LB
```

---

## 🔄 FLUXO DE DADOS E PROCESSING

### Pipeline de Processamento de Logs

```mermaid
sequenceDiagram
    participant App as Aplicação
    participant Producer as Log Producer Service
    participant Kafka as Kafka Cluster
    participant Consumer as Log Consumer Service
    participant DB as PostgreSQL
    participant Analytics as Log Analytics Service
    participant Cache as Redis Cache
    participant Gateway as API Gateway
    participant User as Cliente/Usuário

    Note over App,User: Fluxo Completo de Processamento de Logs

    App->>Producer: Log Event (HTTP POST)
    Producer->>Producer: Validate & Transform
    Producer->>Kafka: Publish to application-logs topic
    
    Kafka->>Consumer: Consume log message
    Consumer->>Consumer: Process & Enrich
    Consumer->>DB: Store processed log
    Consumer->>Kafka: Publish to processed-logs topic (se necessário)
    
    Analytics->>DB: Query aggregated data
    Analytics->>Cache: Cache frequent queries
    
    User->>Gateway: GET /api/analytics/logs
    Gateway->>Analytics: Forward request
    Analytics->>Cache: Check cache first
    
    alt Cache Hit
        Cache-->>Analytics: Return cached data
    else Cache Miss  
        Analytics->>DB: Query database
        DB-->>Analytics: Return data
        Analytics->>Cache: Update cache
    end
    
    Analytics-->>Gateway: Return analytics data
    Gateway-->>User: JSON response
```

### Fluxo de Stock Updates (Teste de Tráfego)

```mermaid
sequenceDiagram
    participant Script as Workflow Script
    participant App as SimpleStockApplication
    participant Health as Health Check
    participant Test as Test Endpoints
    participant Metrics as Metrics Collector

    Note over Script,Metrics: Workflow de 300 Mensagens - Score: 92/100

    Script->>Script: Phase 1: Prerequisites Check
    Script->>App: Start application (JVM optimized)
    App->>App: Initialize Spring Boot
    App->>Health: Register health endpoint
    
    Script->>Health: GET /actuator/health
    Health-->>Script: {"status":"UP"}
    
    loop 300 Messages Distribution
        Script->>Health: 30% requests (90 msgs)
        Health-->>Script: Response ~6ms
        
        Script->>App: 50% requests to /api/v1/stocks (150 msgs)
        App-->>Script: Response ~7ms
        
        Script->>Test: 15% requests to /test (45 msgs)
        Test-->>Script: Response ~3ms
        
        Script->>Health: 5% requests to /actuator/info (15 msgs)
        Health-->>Script: Response ~3ms
    end
    
    Script->>Metrics: Collect performance data
    Metrics->>Metrics: Calculate scores
    Metrics-->>Script: Final report
    
    Note over Script,Metrics: Result: 100% success, 29.84 req/s, 3.67ms avg latency
```

---

## 📊 MÉTRICAS E MONITORAMENTO

### Observabilidade Stack

```mermaid
graph TB
    subgraph "APLICAÇÕES"
        A1[SimpleStockApplication<br/>Actuator Endpoints]
        A2[Microservices<br/>Micrometer Metrics]
        A3[Kafka Brokers<br/>JMX Metrics]
    end
    
    subgraph "COLETA DE MÉTRICAS"
        subgraph "Application Metrics"
            AM1[/actuator/health<br/>Health Status]
            AM2[/actuator/metrics<br/>Application Metrics]
            AM3[/actuator/prometheus<br/>Prometheus Format]
        end
        
        subgraph "Infrastructure Metrics"
            IM1[Kafka JMX<br/>Broker Metrics<br/>Topic Metrics<br/>Consumer Lag]
            IM2[System Metrics<br/>CPU, Memory<br/>Network, Disk]
        end
    end
    
    subgraph "ARMAZENAMENTO"
        P[Prometheus Server<br/>Time Series DB<br/>Scraping: 15s interval]
    end
    
    subgraph "VISUALIZAÇÃO"
        G[Grafana<br/>Dashboards<br/>Alerting Rules]
        
        subgraph "Dashboards"
            D1[Application Performance<br/>Throughput, Latency<br/>Error Rate]
            D2[Kafka Cluster<br/>Broker Health<br/>Topic Metrics<br/>Consumer Lag]
            D3[System Overview<br/>Resource Usage<br/>Network Traffic]
        end
    end
    
    subgraph "ALERTAS"
        AL[Alert Manager<br/>Notification Rules<br/>Channels: Slack, Email]
    end
    
    A1 --> AM1
    A1 --> AM2
    A1 --> AM3
    A2 --> AM2
    A2 --> AM3
    A3 --> IM1
    
    AM1 --> P
    AM2 --> P
    AM3 --> P
    IM1 --> P
    IM2 --> P
    
    P --> G
    G --> D1
    G --> D2
    G --> D3
    
    P --> AL
```

---

## 🚀 DEPLOYMENT WORKFLOWS

### Pipeline de Deploy Local

```mermaid
graph TD
    subgraph "DESENVOLVIMENTO"
        DEV1[Code Changes<br/>IntelliJ/VS Code]
        DEV2[Local Testing<br/>Unit + Integration]
        DEV3[Docker Build<br/>./mvnw clean package]
    end
    
    subgraph "BUILD PROCESS"
        B1[Maven Build<br/>Spring Boot JAR<br/>Dependencies Resolution]
        B2[Docker Image Build<br/>Multi-stage Dockerfile<br/>JRE 17 Alpine]
        B3[Image Tag<br/>kbnt/service-name:version]
    end
    
    subgraph "LOCAL DEPLOYMENT"
        L1[Docker Compose Up<br/>Infrastructure Services<br/>Network Creation]
        L2[Microservices Deploy<br/>Health Checks<br/>Service Discovery]
        L3[Integration Testing<br/>End-to-End Validation]
    end
    
    subgraph "VALIDATION"
        V1[Workflow Scripts<br/>complete-validation-workflow.ps1<br/>300 Messages Test]
        V2[Performance Testing<br/>Latency < 10ms<br/>Throughput > 25 req/s]
        V3[Report Generation<br/>JSON + CSV Reports<br/>Score Calculation]
    end
    
    DEV1 --> DEV2
    DEV2 --> DEV3
    DEV3 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> L1
    L1 --> L2
    L2 --> L3
    L3 --> V1
    V1 --> V2
    V2 --> V3
```

### Pipeline de Deploy Kubernetes

```mermaid
graph TD
    subgraph "PREPARAÇÃO"
        P1[Kubernetes Cluster<br/>Local: Kind/Minikube<br/>Remote: OpenShift]
        P2[Namespace Creation<br/>microservices, kafka<br/>RBAC Configuration]
        P3[Secrets & ConfigMaps<br/>Database Credentials<br/>Kafka Configuration]
    end
    
    subgraph "INFRASTRUCTURE DEPLOY"
        I1[Strimzi Operator<br/>Kafka CRDs<br/>Operator Deployment]
        I2[Kafka Cluster<br/>3 Brokers + Zookeeper<br/>Persistent Storage]
        I3[Database Services<br/>PostgreSQL + Redis<br/>StatefulSets]
    end
    
    subgraph "APPLICATION DEPLOY"
        A1[ConfigMap Apply<br/>Application Configuration<br/>Environment Variables]
        A2[Service Deployment<br/>Producer + Consumer<br/>Analytics Services]
        A3[Service Exposure<br/>LoadBalancer/Ingress<br/>External Access]
    end
    
    subgraph "VALIDATION & TESTING"
        T1[Health Checks<br/>Readiness/Liveness<br/>Probe Configuration]
        T2[Integration Testing<br/>Service-to-Service<br/>Kafka Connectivity]
        T3[Performance Testing<br/>Load Testing<br/>Resource Monitoring]
    end
    
    P1 --> P2
    P2 --> P3
    P3 --> I1
    I1 --> I2
    I2 --> I3
    I3 --> A1
    A1 --> A2
    A2 --> A3
    A3 --> T1
    T1 --> T2
    T2 --> T3
```

---

## 🔧 CONFIGURAÇÕES TÉCNICAS DETALHADAS

### Configuração JVM Otimizada

```yaml
# JVM Settings para Ambiente Local (usado no workflow)
heap:
  initial: 128m          # -Xms128m
  maximum: 256m          # -Xmx256m
  
garbage_collector:
  type: G1GC             # -XX:+UseG1GC
  max_pause: 100ms       # -XX:MaxGCPauseMillis=100

network:
  prefer_ipv4: true      # -Djava.net.preferIPv4Stack=true
  
application:
  server_address: 127.0.0.1    # -Dserver.address=127.0.0.1
  server_port: 8080            # -Dserver.port=8080
  spring_profile: local        # -Dspring.profiles.active=local
  
logging:
  level:
    springframework: WARN     # -Dlogging.level.org.springframework=WARN
    
performance_results:
  memory_usage: 213.52MB      # Working Set
  cpu_time: 7.08s             # Total CPU Time
  threads: 69                 # Active Threads
  throughput: 29.84_req_per_s # Requests per Second
  average_latency: 3.67ms     # Average Response Time
```

### Configuração Kafka (Kubernetes)

```yaml
# Kafka Cluster Configuration
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kafka-cluster
  namespace: kafka
spec:
  kafka:
    version: 3.4.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls  
        port: 9093
        type: internal
        tls: true
    config:
      # Replicação e durabilidade
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      default.replication.factor: 3
      min.insync.replicas: 2
      
      # Performance
      num.network.threads: 8
      num.io.threads: 8
      socket.send.buffer.bytes: 102400
      socket.receive.buffer.bytes: 102400
      
      # Logs
      log.retention.hours: 168
      log.segment.bytes: 1073741824
      log.retention.check.interval.ms: 300000
      compression.type: "snappy"
      
      # Topics
      auto.create.topics.enable: true
      delete.topic.enable: true
      num.partitions: 3
      
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
    
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
        
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 20Gi
      deleteClaim: false
    resources:
      requests:
        memory: 1Gi
        cpu: 500m
      limits:
        memory: 2Gi
        cpu: 1000m
```

---

## 📈 RESULTADOS DE PERFORMANCE VALIDADOS

### Métricas do Workflow Executado

```yaml
execution_results:
  execution_id: "20250830-205417"
  environment: "Local-Development"
  total_duration: 13.69s
  
  test_configuration:
    total_messages: 300
    distribution:
      health_endpoint: 90    # 30%
      stocks_endpoint: 150   # 50%  
      test_endpoint: 45      # 15%
      info_endpoint: 15      # 5%
  
  performance_metrics:
    success_rate: 100.0%
    throughput: 29.84 req/s
    latency:
      average: 3.67ms
      minimum: 1.15ms
      maximum: 6.5ms
    
  resource_usage:
    memory_working_set: 213.52MB
    memory_peak: 235.77MB
    cpu_time: 7.08s
    threads: 69
    
  quality_score:
    total: 92/100
    breakdown:
      success_rate_weight: 40% # 40 points
      latency_score_weight: 30% # 29 points  
      throughput_score_weight: 20% # 20 points
      stability_score_weight: 10% # 10 points
      
  optimization_applied:
    - "JVM otimizada para ambiente local"
    - "Configuração de rede localhost para reduzir latência"
    - "Sistema estável - pronto para aumentar carga"
    
  classification: "EXCELLENT"
  recommendation: "Pronto para aumentar carga de testes"
```

---

## 🎯 COMPONENTES CRÍTICOS IDENTIFICADOS

### Pontos de Atenção para Produção

```mermaid
graph TD
    subgraph "GAPS ARQUITETURAIS"
        G1[Arquitetura Monolítica<br/>SimpleStockApplication<br/>Viola princípios hexagonais]
        G2[Ausência de Testes Unitários<br/>Cobertura: 0%<br/>Meta: 80%+]
        G3[Configurações Hardcoded<br/>Sem profiles por ambiente<br/>Needs: local/test/staging/prod]
        G4[Tratamento de Erros Básico<br/>Sem padronização<br/>Needs: GlobalExceptionHandler]
    end
    
    subgraph "MELHORIAS PRIORITÁRIAS"
        M1[Refatoração Hexagonal<br/>Domain/Application/Infrastructure<br/>Separação de responsabilidades]
        M2[Implementação de Cache<br/>Redis para performance<br/>@Cacheable annotations]
        M3[Validação de Entrada<br/>Bean Validation<br/>@Valid annotations]
        M4[Observabilidade<br/>Metrics, Tracing<br/>Prometheus, Jaeger]
    end
    
    subgraph "SEGURANÇA"
        S1[Autenticação/Autorização<br/>JWT, OAuth2<br/>Spring Security]
        S2[Network Policies<br/>Kubernetes isolation<br/>Egress/Ingress rules]
        S3[Secrets Management<br/>Encrypted credentials<br/>Vault integration]
        S4[TLS Encryption<br/>Service-to-service<br/>Certificate management]
    end
    
    G1 --> M1
    G2 --> M2
    G3 --> M3
    G4 --> M4
    
    M1 --> S1
    M2 --> S2
    M3 --> S3
    M4 --> S4
```

---

## 🔄 ROADMAP DE IMPLEMENTAÇÃO

### Sprint Planning

```yaml
sprint_1: # 1-2 semanas
  objetivo: "Refatoração Arquitetural Básica"
  tasks:
    - refatorar_simple_stock_application_para_hexagonal
    - implementar_testes_unitarios_basicos
    - configurar_profiles_ambiente: [local, test, staging]
    - adicionar_bean_validation
  deliverables:
    - arquitetura_hexagonal_implementada
    - cobertura_testes: 60%
    - configuracao_por_ambiente
    
sprint_2: # 2-3 semanas  
  objetivo: "Performance e Observabilidade"
  tasks:
    - implementar_global_exception_handler
    - adicionar_cache_redis_local
    - implementar_testes_contrato
    - configurar_prometheus_metrics
  deliverables:
    - tratamento_erro_padronizado
    - cache_implementado
    - metricas_observabilidade
    
sprint_3: # 1 semana
  objetivo: "Segurança e Testes Avançados"
  tasks:
    - testes_seguranca_basicos
    - testes_resiliencia_circuit_breaker
    - analise_cobertura_codigo
    - documentacao_api_openapi
  deliverables:
    - security_tests_implementados
    - circuit_breaker_configurado
    - documentacao_api_completa

quality_gates:
  cobertura_testes: ">= 80%"
  performance: ">= 25 req/s"  
  latencia_media: "< 10ms"
  score_sonarqube: ">= 80%"
  security_score: ">= 85%"
```

---

## 📋 CONCLUSÕES E RECOMENDAÇÕES

### Status Atual do Sistema

```yaml
sistema_funcional:
  status: "✅ OPERACIONAL"
  score_workflow: "92/100"
  classificacao: "EXCELENTE"
  
pontos_fortes:
  performance:
    - throughput: "29.84 req/s"
    - latencia_media: "3.67ms"  
    - taxa_sucesso: "100%"
  automacao:
    - workflow_completo: "7 fases automatizadas"
    - zero_intervencao_manual: true
    - custo_execucao: "R$ 0,00"
  infraestrutura:
    - containerizacao: "Docker + Docker Compose"
    - orquestracao: "Kubernetes ready"
    - kafka_ecosystem: "Completo e configurado"
    
gaps_criticos:
  arquitetura:
    - monolitico_vs_hexagonal: "❌ Violação de princípios"
    - separacao_responsabilidades: "❌ Tudo em uma classe"
  testes:
    - cobertura_unitaria: "❌ 0%"
    - testes_integracao: "✅ Funcionais"
  configuracao:
    - hardcoded_values: "❌ Sem profiles"
    - environment_specific: "❌ Apenas local"
    
proximos_passos:
  imediatos:
    1: "Refatoração arquitetural para hexagonal"
    2: "Implementação de testes unitários" 
    3: "Configuração de profiles por ambiente"
  medio_prazo:
    1: "Implementação de segurança (authn/authz)"
    2: "Observabilidade completa (metrics, tracing)"
    3: "Testes de resiliência e chaos engineering"
  longo_prazo:
    1: "Deploy em ambiente produtivo"
    2: "CI/CD pipeline completo"
    3: "Multi-cloud deployment strategy"
    
avaliacao_final:
  workflow_score: "92/100 - EXCELENTE"
  arquitetura_score: "60/100 - NECESSITA MELHORIAS"
  recomendacao: "Sistema funcional e performático, mas requer refatoração arquitetural antes de produção"
  prioridade: "ALTA - Refatoração imediata recomendada"
```

---

**📝 NOTA IMPORTANTE:** Esta documentação é **INTERNA** e contém detalhes técnicos sensíveis da arquitetura. **NÃO DEVE SER PUBLICADA** no repositório GitHub público.
