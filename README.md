# KBNT Microservices Kafka Logs System

Sistema de microserviços para gerenciamento de estoque virtual com arquitetura orientada a eventos usando Kafka para processamento de logs e monitoramento.

## 🏗️ Arquitetura do Sistema - Visão Geral

```mermaid
graph TB
    %% Client Layer
    Client[Client/Browser] -->|HTTP REST| Gateway[API Gateway<br/>Port 8090<br/>Spring Cloud Gateway]
    Client -->|Direct Access| KafkaUI[Kafka UI<br/>Port 8080<br/>Monitoring]
    Client -->|Direct Access| Kibana[Kibana<br/>Port 5601<br/>Analytics]
    
    %% API Gateway Layer
    Gateway -->|Route /api/v1/virtual-stock/**| VStock[Virtual Stock Service<br/>Port 8086<br/>PostgreSQL + Kafka]
    Gateway -->|Route /api/v1/logs/**| LogProd[Log Producer Service<br/>Port 8081<br/>Kafka Producer]
    Gateway -->|Route /api/v1/kbnt-logs/**| KBNTLog[KBNT Log Service<br/>Port 8082<br/>Elasticsearch]
    
    %% Business Services
    VStock -->|Produces Events| Kafka[Apache Kafka<br/>Port 9092<br/>Event Streaming]
    VStock -->|Store Data| Postgres[(PostgreSQL<br/>Port 5432<br/>Database)]
    
    %% Message Processing Layer
    Kafka -->|Consume Events| LogConsumer[Log Consumer Service<br/>Port 8084<br/>Event Consumer]
    Kafka -->|Consume Stock Events| StockConsumer[Stock Consumer Service<br/>Port 8085<br/>Business Logic]
    Kafka -->|UI Management| KafkaUI
    
    %% Analytics & Monitoring Layer
    LogConsumer -->|Index Logs| Elasticsearch[(Elasticsearch<br/>Port 9200<br/>Search Engine)]
    KBNTLog -->|Store/Query| Elasticsearch
    LogAnalytics[Log Analytics Service<br/>Port 8083<br/>Data Processing] -->|Query Data| Elasticsearch
    Elasticsearch -->|Visualization| Kibana
    
    %% Infrastructure
    Kafka -->|Coordination| Zookeeper[Zookeeper<br/>Port 2181<br/>Cluster Management]
    
    %% Docker Container Grouping
    subgraph "Docker Compose Network"
        Gateway
        VStock
        LogProd
        KBNTLog
        LogConsumer
        StockConsumer
        LogAnalytics
        Kafka
        Zookeeper
        Postgres
        Elasticsearch
        Kibana
        Kafka_UI
    end
    
    %% Status Colors
    classDef running fill:#90EE90,stroke:#333,stroke-width:2px
    classDef failed fill:#FFB6C1,stroke:#333,stroke-width:2px
    classDef infrastructure fill:#87CEEB,stroke:#333,stroke-width:2px
    classDef monitoring fill:#DDA0DD,stroke:#333,stroke-width:2px
    
    class Gateway,VStock,KBNTLog,LogAnalytics,LogConsumer running
    class LogProd,StockConsumer failed
    class Kafka,Zookeeper,Postgres,Elasticsearch infrastructure
    class KafkaUI,Kibana monitoring
```

## 🏛️ Arquitetura Hexagonal - Virtual Stock Service

```mermaid
graph TB
    subgraph "External Systems"
        CLIENT[Trading Client]
        EXT_API[External APIs]
        GRAFANA[Grafana Dashboard]
        KIBANA_DASH[Kibana Analytics]
    end
    
    subgraph "Virtual Stock Service - Hexagonal Architecture"
        subgraph "Input Ports"
            REST_PORT[HTTP REST Port]
            MGMT_PORT[Management Port]
        end
        
        subgraph "Domain Core"
            STOCK_AGG[Stock Aggregate<br/>stockId, productId, quantity<br/>unitPrice, status]
            STOCK_EVENT[StockUpdatedEvent<br/>CREATE, UPDATE, RESERVE]
            BIZ_RULES[Business Rules<br/>canReserve, isLowStock]
            VALUE_OBJ[Value Objects<br/>StockId, ProductId]
        end
        
        subgraph "Application Layer"
            STOCK_UC[StockManagementUseCase<br/>Business operations]
            APP_SERVICE[StockApplicationService<br/>Workflow coordination]
            EVENT_PUB[EventPublisher<br/>Domain events]
        end
        
        subgraph "Output Ports"
            KAFKA_PORT[Kafka Publisher Port]
            DB_PORT[Repository Port]
            METRICS_PORT[Metrics Port]
        end
        
        subgraph "Input Adapters"
            REST_CTRL[VirtualStockController<br/>HTTP REST API]
            HEALTH_CTRL[HealthController<br/>Actuator endpoints]
        end
        
        subgraph "Output Adapters"
            KAFKA_PUB[KafkaPublisherAdapter<br/>Event streaming]
            JPA_REPO[JpaRepositoryAdapter<br/>PostgreSQL integration]
            PROMETHEUS[PrometheusAdapter<br/>Metrics collection]
        end
    end
    
    subgraph "Red Hat AMQ Streams - Kafka"
        TOPIC_STOCK[virtual-stock-updates<br/>Main business events]
        TOPIC_HIGH[high-priority-updates<br/>Critical trading events]
        TOPIC_RETRY[retry-topic<br/>Failed message recovery]
        TOPIC_DLT[dead-letter-topic<br/>Unprocessable messages]
    end
    
    subgraph "💾 Data Layer"
        POSTGRES_DB[(🐘 PostgreSQL<br/>Stock persistence)]
        ELASTIC_DB[(🔍 Elasticsearch<br/>Logging & metrics)]
    end
    
    CLIENT --> REST_CTRL
    REST_CTRL --> REST_PORT
    REST_PORT --> STOCK_UC
    STOCK_UC --> APP_SERVICE
    APP_SERVICE --> STOCK_AGG
    STOCK_AGG --> STOCK_EVENT
    APP_SERVICE --> EVENT_PUB
    EVENT_PUB --> KAFKA_PORT
    KAFKA_PORT --> KAFKA_PUB
    APP_SERVICE --> DB_PORT
    DB_PORT --> JPA_REPO
    
    KAFKA_PUB --> TOPIC_STOCK
    PROMETHEUS --> GRAFANA
    JPA_REPO --> POSTGRES_DB
    
    style STOCK_AGG fill:#e1f5fe
    style STOCK_EVENT fill:#e8f5e8
    style KAFKA_PUB fill:#fff3e0
    style POSTGRES_DB fill:#f3e5f5
    style ELASTIC_DB fill:#e0f2f1
```

## 🔄 Workflow de Processamento de Logs

```mermaid
graph TB
    subgraph "Log Message Structure"
        LOG_MSG[LogMessage<br/>level, message, serviceName<br/>category, timestamp, correlationId<br/>userId, sessionId, metadata]
    end
    
    subgraph "REST API Layer"
        REST_CTRL[UnifiedLogController<br/>POST /api/v1/logs<br/>Spring Boot 3.2 + Bean Validation]
        REST_CTRL -->|Validate & Enrich| PRODUCER[UnifiedLogProducer<br/>Auto-timestamp, UUID correlation<br/>Service name assignment]
    end
    
    subgraph "Intelligent Routing"
        PRODUCER -->|Route Logic| ROUTER{Topic Router<br/>Category + Level Analysis}
        ROUTER -->|Financial/Transaction| FINANCIAL_TOPIC[kbnt-financial-logs<br/>High priority, extended retention]
        ROUTER -->|Audit/Security| AUDIT_TOPIC[kbnt-audit-logs<br/>Compliance, long retention]
        ROUTER -->|ERROR/FATAL| ERROR_TOPIC[kbnt-error-logs<br/>Alert integration, 30 days]
        ROUTER -->|Default| APP_TOPIC[kbnt-application-logs<br/>General purpose, 7 days]
    end
    
    subgraph "AMQ Streams Topics"
        FINANCIAL_TOPIC -->|Partitions: 3, Compression: lz4| KAFKA_CLUSTER[Apache Kafka 7.4.0<br/>Zookeeper coordination]
        AUDIT_TOPIC -->|Partitions: 4, Retention: 90d| KAFKA_CLUSTER
        ERROR_TOPIC -->|Partitions: 4, Retention: 30d| KAFKA_CLUSTER
        APP_TOPIC -->|Partitions: 6, Compression: snappy| KAFKA_CLUSTER
    end
    
    subgraph "Log Consumer Processing"
        KAFKA_CLUSTER --> CONSUMER[Log Consumer Service<br/>KafkaListener + Error handling<br/>Dead letter queue support]
        CONSUMER -->|Transform & Index| ELASTIC_INDEX[Elasticsearch Indexing<br/>Time-based indices<br/>Structured mapping]
    end
    
    subgraph "Analytics & Monitoring"
        ELASTIC_INDEX --> KIBANA_DASH[Kibana Dashboards<br/>Real-time analytics<br/>Custom visualizations]
        ELASTIC_INDEX --> ALERT_MGR[Alert Manager<br/>Error threshold monitoring<br/>SLA tracking]
    end
    
    LOG_MSG --> REST_CTRL
    
    style LOG_MSG fill:#e3f2fd
    style FINANCIAL_TOPIC fill:#fff3e0
    style AUDIT_TOPIC fill:#f3e5f5
    style ERROR_TOPIC fill:#ffebee
    style APP_TOPIC fill:#e8f5e8
```

## 🔄 Fluxo de Mensagens Kafka Detalhado

```mermaid
sequenceDiagram
    participant Client as Client
    participant Gateway as API Gateway
    participant VStock as Virtual Stock
    participant Kafka as Kafka
    participant Consumer as Log Consumer
    participant DB as PostgreSQL
    participant ES as Elasticsearch
    
    Note over Client,ES: Complete Message Flow
    
    Client->>Gateway: POST /api/v1/virtual-stock/stocks
    Gateway->>VStock: Route request
    
    VStock->>VStock: Validate business rules
    VStock->>DB: Persist stock data
    DB-->>VStock: Confirm persistence
    
    VStock->>VStock: Create StockUpdatedEvent
    VStock->>Kafka: Publish to virtual-stock-updates
    
    Note over Kafka: Message routing to multiple topics
    Kafka->>Kafka: Route by event type
    
    Kafka-->>Consumer: Consume stock events
    Consumer->>Consumer: Process & transform
    Consumer->>ES: Index processed data
    
    VStock-->>Gateway: HTTP 201 Created
    Gateway-->>Client: Success response
    
    Note over Consumer,ES: Async processing continues
    Consumer->>ES: Bulk index operations
    ES-->>Consumer: Confirm indexing
```

## 🚀 Serviços e Status

### ✅ **Serviços Funcionais:**
- **API Gateway** (Port 8090) - Spring Cloud Gateway
- **Virtual Stock Service** (Port 8086) - Hexagonal Architecture + PostgreSQL
- **KBNT Log Service** (Port 8082) - Elasticsearch Integration
- **Log Analytics Service** (Port 8083) - Data Processing
- **Log Consumer Service** (Port 8084) - Kafka Consumer
- **PostgreSQL** (Port 5432) - Database
- **Apache Kafka** (Port 9092) - Event Streaming
- **Zookeeper** (Port 2181) - Cluster Coordination
- **Elasticsearch** (Port 9200) - Search Engine
- **Kibana** (Port 5601) - Analytics Dashboard
- **Kafka UI** (Port 8080) - Monitoring Interface

### ❌ **Serviços com Problemas:**
- **Log Producer Service** (Port 8081) - Exit 1
- **Stock Consumer Service** (Port 8085) - Exit 1

## 🛠️ Tecnologias Utilizadas

### **Backend Services:**
- **Java 17** - Runtime
- **Spring Boot 3.2.0 / 2.7.18** - Framework
- **Spring Cloud Gateway** - API Gateway
- **Maven** - Build Tool
- **Hexagonal Architecture** - Design Pattern

### **Data & Messaging:**
- **Apache Kafka 7.4.0** - Event Streaming
- **PostgreSQL 15** - Relational Database
- **Elasticsearch 8.8.0** - Search Engine
- **Zookeeper** - Kafka Cluster Management

### **Monitoring & Analytics:**
- **Kibana** - Data Visualization
- **Kafka UI** - Kafka Monitoring
- **Spring Boot Actuator** - Health Checks
- **Elasticsearch** - Log Aggregation

### **Infrastructure:**
- **Docker & Docker Compose** - Containerization
- **WSL Ubuntu** - Development Environment

## 🔧 Como Executar

### **Pré-requisitos:**
- Docker & Docker Compose
- WSL Ubuntu (Windows)
- Java 17+ e Maven (para desenvolvimento)

### **Iniciar Sistema:**
```bash
cd docker
docker-compose up -d
```

### **Verificar Status:**
```bash
docker-compose ps
```

### **Parar Sistema:**
```bash
docker-compose down
```

## 📡 Endpoints da API

### **Via API Gateway (Port 8090):**

#### **Virtual Stock Service:**
```bash
# GET - Listar stocks
curl -X GET "http://localhost:8090/api/v1/virtual-stock/stocks"

# POST - Criar stock
curl -X POST "http://localhost:8090/api/v1/virtual-stock/stocks" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "PROD001",
    "symbol": "AAPL",
    "productName": "Apple Inc.",
    "initialQuantity": 100,
    "unitPrice": 150.50,
    "createdBy": "admin"
  }'
```

#### **KBNT Log Service:**
```bash
# GET - Health check
curl -X GET "http://localhost:8090/api/v1/kbnt-logs/health"

# POST - Criar log
curl -X POST "http://localhost:8090/api/v1/kbnt-logs/logs" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Test log via gateway",
    "level": "INFO"
  }'
```

#### **Health Check:**
```bash
curl -X GET "http://localhost:8090/actuator/health"
```

### **Acesso Direto aos Serviços:**
- **Kafka UI:** http://localhost:8080
- **Kibana:** http://localhost:5601
- **Elasticsearch:** http://localhost:9200
- **Virtual Stock Service:** http://localhost:8086
- **KBNT Log Service:** http://localhost:8082

## 🔍 Monitoramento

### **Logs dos Serviços:**
```bash
# Logs do API Gateway
docker-compose logs api-gateway

# Logs do Virtual Stock Service
docker-compose logs virtual-stock-service

# Logs do Kafka
docker-compose logs kafka
```

### **Health Checks:**
Todos os serviços Spring Boot expõem endpoints `/actuator/health` para monitoramento.

## 🗂️ Estrutura do Projeto

```
estudosKBNT_Kafka_Logs/
├── docker/
│   ├── docker-compose.yml          # Orquestração dos containers
│   └── ...
├── microservices/
│   ├── api-gateway/                 # Spring Cloud Gateway
│   ├── virtual-stock-service/       # Gestão de Estoque + PostgreSQL
│   ├── kbnt-log-service/           # Logging + Elasticsearch
│   ├── log-producer-service/       # Kafka Producer
│   ├── log-consumer-service/       # Kafka Consumer
│   ├── log-analytics-service/      # Analytics
│   └── kbnt-stock-consumer-service/ # Stock Event Consumer
└── README.md                       # Este arquivo
```

## 🚦 Fluxo de Dados

1. **Cliente** → **API Gateway** (entrada unificada)
2. **API Gateway** → **Virtual Stock Service** (operações de estoque)
3. **Virtual Stock Service** → **Kafka** (eventos de negócio)
4. **Virtual Stock Service** → **PostgreSQL** (persistência)
5. **Kafka** → **Log Consumer Service** (processamento assíncrono)
6. **Log Consumer** → **Elasticsearch** (indexação)
7. **Elasticsearch** → **Kibana** (visualização)
8. **Kafka UI** ↔ **Kafka** (monitoramento)

## 🎯 Principais Features

- ✅ **API Gateway** com roteamento inteligente
- ✅ **Arquitetura Hexagonal** no Virtual Stock Service
- ✅ **Event Sourcing** com Kafka
- ✅ **Full-text Search** com Elasticsearch
- ✅ **Real-time Analytics** com Kibana
- ✅ **Health Monitoring** com Actuator
- ✅ **Containerização** completa
- ✅ **CORS** configurado
- ✅ **Database Integration** PostgreSQL

## 🔧 Desenvolvimento

### **Build dos Serviços:**
```bash
# Build individual
cd microservices/virtual-stock-service
mvn clean compile

# Build via Docker
docker-compose build --no-cache
```

### **Logs de Debug:**
Os serviços principais têm logging detalhado configurado para debugging.

## 📝 Licença

Projeto educacional para estudos de microserviços e Kafka.
