# 🔄 Mermaid Diagrams - Workflow de Tráfego de Mensagens

## 📊 Diagrama 1: Fluxo Geral de Mensagens

```mermaid
flowchart TD
    A[Aplicação Cliente] -->|POST /api/logs| B[Log Producer Service]
    B -->|Validação| C{Tipo de Log}
    
    C -->|ERROR/FATAL| D[error-logs Topic]
    C -->|AUDIT| E[audit-logs Topic]  
    C -->|FINANCIAL| F[financial-logs Topic]
    C -->|INFO/DEBUG/WARN| G[application-logs Topic]
    
    D --> H[Error Consumer]
    E --> I[Audit Consumer]
    F --> J[Financial Consumer] 
    G --> K[Application Consumer]
    
    H --> L[Alert Engine]
    I --> M[Compliance Engine]
    J --> N[Fraud Detection]
    K --> O[Performance Analysis]
    
    L --> P[Notification Service]
    M --> Q[Security Reports]
    N --> R[Risk Assessment]
    O --> S[Metrics Dashboard]
```

## 🏗️ Diagrama 2: Arquitetura de Componentes

```mermaid
graph TB
    subgraph "Application Layer"
        APP1[Web App]
        APP2[Mobile App]
        APP3[Backend Services]
    end
    
    subgraph "API Gateway"
        GW[Spring Cloud Gateway]
    end
    
    subgraph "Microservices"
        PROD[Log Producer Service]
        CONS[Log Consumer Service]
        CONFIG[Config Service]
    end
    
    subgraph "Kafka Cluster"
        K1[Kafka Broker 1]
        K2[Kafka Broker 2] 
        K3[Kafka Broker 3]
        ZK1[Zookeeper 1]
        ZK2[Zookeeper 2]
        ZK3[Zookeeper 3]
    end
    
    subgraph "Storage Layer"
        PG[PostgreSQL]
        ES[Elasticsearch]
        S3[Object Storage]
    end
    
    subgraph "Monitoring"
        PROM[Prometheus]
        GRAF[Grafana]
        JAEG[Jaeger]
    end
    
    APP1 --> GW
    APP2 --> GW
    APP3 --> GW
    GW --> PROD
    GW --> CONS
    
    PROD --> K1
    PROD --> K2
    PROD --> K3
    
    K1 --> CONS
    K2 --> CONS  
    K3 --> CONS
    
    CONS --> PG
    CONS --> ES
    CONS --> S3
    
    PROD --> PROM
    CONS --> PROM
    PROM --> GRAF
```

## ⚡ Diagrama 3: Fluxo de Processamento por Tipo

```mermaid
sequenceDiagram
    participant Client as Cliente
    participant Producer as Producer Service
    participant Kafka as Kafka Cluster
    participant Consumer as Consumer Service
    participant Processing as Processing Engine
    participant Storage as Storage
    participant Monitor as Monitoring
    
    Client->>Producer: POST /api/logs
    Producer->>Producer: Validate payload
    Producer->>Producer: Route by log type
    Producer->>Kafka: Send to appropriate topic
    Kafka-->>Producer: ACK
    Producer-->>Client: 202 Accepted
    
    loop Consumer Processing
        Consumer->>Kafka: Poll messages
        Kafka-->>Consumer: Message batch
        Consumer->>Processing: Process by type
        
        alt Error Log
            Processing->>Processing: Generate alert
            Processing->>Monitor: Send metrics
        else Audit Log
            Processing->>Processing: Compliance check
            Processing->>Storage: Store for reports
        else Financial Log
            Processing->>Processing: Fraud detection
            Processing->>Storage: Secure storage
        else Application Log
            Processing->>Processing: Performance analysis
            Processing->>Monitor: Update dashboard
        end
        
        Processing->>Storage: Persist processed data
        Consumer->>Kafka: Commit offset
    end
```

## 🛡️ Diagrama 4: Padrões de Resiliência

```mermaid
graph TD
    subgraph "Producer Resilience"
        P1[Retry Policy] --> P2[Circuit Breaker]
        P2 --> P3[Bulkhead Pattern]
        P3 --> P4[Timeout Control]
    end
    
    subgraph "Kafka Resilience" 
        K1[Multi-Broker Replication] --> K2[Leader Election]
        K2 --> K3[ISR Management]
        K3 --> K4[Log Compaction]
    end
    
    subgraph "Consumer Resilience"
        C1[Consumer Groups] --> C2[Auto Rebalancing] 
        C2 --> C3[Dead Letter Queue]
        C3 --> C4[Offset Management]
    end
    
    subgraph "Infrastructure Resilience"
        I1[Auto-scaling] --> I2[Health Checks]
        I2 --> I3[Rolling Updates] 
        I3 --> I4[Backup & Recovery]
    end
    
    P4 --> K1
    K4 --> C1  
    C4 --> I1
```

## 📊 Diagrama 5: Pipeline de Observabilidade

```mermaid
flowchart LR
    subgraph "Metrics Collection"
        M1[Application Metrics]
        M2[Infrastructure Metrics] 
        M3[Business Metrics]
    end
    
    subgraph "Logging"
        L1[Application Logs]
        L2[Kafka Logs]
        L3[System Logs]
    end
    
    subgraph "Tracing"
        T1[Request Tracing]
        T2[Message Tracing]
        T3[Error Tracing]
    end
    
    subgraph "Processing"
        PROM[Prometheus]
        ELK[ELK Stack]
        JAEGER[Jaeger]
    end
    
    subgraph "Visualization"
        GRAF[Grafana Dashboards]
        KIBANA[Kibana]
        ALERTS[Alert Manager]
    end
    
    M1 --> PROM
    M2 --> PROM
    M3 --> PROM
    
    L1 --> ELK
    L2 --> ELK  
    L3 --> ELK
    
    T1 --> JAEGER
    T2 --> JAEGER
    T3 --> JAEGER
    
    PROM --> GRAF
    PROM --> ALERTS
    ELK --> KIBANA
    JAEGER --> GRAF
```
