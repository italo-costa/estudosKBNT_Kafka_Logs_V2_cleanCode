# 🏗️ ARQUITETURA DE DEPLOYMENT - KBNT Kafka Logs

## 🎯 Visão Geral da Arquitetura

Este documento apresenta a arquitetura completa de deployment do sistema KBNT Kafka Logs, mostrando como os componentes são organizados em diferentes ambientes e estratégias de escalabilidade.

---

## 🌐 Arquitetura Global de Deployment

```mermaid
graph TB
    subgraph "☁️ CLOUD INFRASTRUCTURE"
        subgraph "🌍 External Services"
            EXT1[🌐 GitHub Repository]
            EXT2[📊 Docker Hub Registry]
            EXT3[🔍 External Monitoring]
        end
        
        subgraph "🏠 ON-PREMISE DEPLOYMENT"
            subgraph "💻 Development Environment"
                DEV1[🧪 Local Docker]
                DEV2[🔧 IDE Integration]
                DEV3[🧪 Unit Tests]
            end
            
            subgraph "🎭 Staging Environment"
                STAGE1[⚖️ Load Balancer]
                STAGE2[📦 Multiple Instances]
                STAGE3[📊 Basic Monitoring]
            end
            
            subgraph "🏭 Production Environment"
                PROD1[🏢 Enterprise Setup]
                PROD2[🔄 High Availability]
                PROD3[📈 Auto Scaling]
                PROD4[🚨 Advanced Alerting]
            end
        end
    end
    
    EXT1 --> DEV1
    DEV1 --> STAGE1
    STAGE1 --> PROD1
    EXT2 --> DEV1
    EXT2 --> STAGE1
    EXT2 --> PROD1
    EXT3 --> PROD4
    
    style EXT1 fill:#e3f2fd
    style DEV1 fill:#e8f5e8
    style STAGE1 fill:#fff3e0
    style PROD1 fill:#fce4ec
```

---

## 🏢 Arquitetura Enterprise de Produção

```mermaid
graph TB
    subgraph "🌐 INTERNET"
        USER[👥 Users/Clients]
    end
    
    subgraph "🛡️ SECURITY LAYER"
        FW[🔥 Firewall]
        SSL[🔐 SSL Termination]
        AUTH[🔑 Authentication]
    end
    
    subgraph "⚖️ LOAD BALANCER TIER"
        LB1[HAProxy Primary]
        LB2[HAProxy Backup]
    end
    
    subgraph "🚪 API GATEWAY TIER"
        API1[API Gateway 1<br/>:8080]
        API2[API Gateway 2<br/>:8081]
        API3[API Gateway 3<br/>:8082]
    end
    
    subgraph "💼 APPLICATION TIER"
        subgraph "📈 Virtual Stock Services"
            VS1[Virtual Stock 1]
            VS2[Virtual Stock 2]
            VS3[Virtual Stock 3]
            VS4[Virtual Stock 4]
        end
        
        subgraph "📨 Message Processing"
            PROD1[Log Producer 1]
            PROD2[Log Producer 2]
            CONS1[Log Consumer 1]
            CONS2[Log Consumer 2]
        end
    end
    
    subgraph "📨 MESSAGE LAYER"
        subgraph "🔧 ZooKeeper Ensemble"
            ZK1[ZooKeeper 1<br/>:2181]
            ZK2[ZooKeeper 2<br/>:2182]
            ZK3[ZooKeeper 3<br/>:2183]
        end
        
        subgraph "📊 Kafka Cluster"
            K1[Kafka Broker 1<br/>:9092]
            K2[Kafka Broker 2<br/>:9093]
            K3[Kafka Broker 3<br/>:9094]
        end
    end
    
    subgraph "💾 DATA TIER"
        subgraph "🗄️ PostgreSQL Cluster"
            PG1[PG Master<br/>:5432]
            PG2[PG Replica 1<br/>:5433]
            PG3[PG Replica 2<br/>:5434]
        end
        
        subgraph "🔍 Elasticsearch Cluster"
            ES1[Elasticsearch 1<br/>:9200]
            ES2[Elasticsearch 2<br/>:9201]
            ES3[Elasticsearch 3<br/>:9202]
        end
        
        subgraph "⚡ Cache Cluster"
            REDIS1[Redis Master]
            REDIS2[Redis Replica 1]
            REDIS3[Redis Replica 2]
        end
    end
    
    subgraph "📊 MONITORING TIER"
        PROM[Prometheus<br/>:9090]
        GRAF[Grafana<br/>:3000]
        ALERT[Alert Manager]
        JAEGER[Jaeger Tracing<br/>:16686]
    end
    
    subgraph "📁 STORAGE TIER"
        VOL1[Application Volumes]
        VOL2[Database Volumes]
        VOL3[Log Volumes]
        BACKUP[Backup Storage]
    end
    
    %% Connections
    USER --> FW
    FW --> SSL
    SSL --> AUTH
    AUTH --> LB1
    AUTH --> LB2
    
    LB1 --> API1
    LB1 --> API2
    LB2 --> API2
    LB2 --> API3
    
    API1 --> VS1
    API1 --> VS2
    API2 --> VS2
    API2 --> VS3
    API3 --> VS3
    API3 --> VS4
    
    VS1 --> K1
    VS2 --> K2
    VS3 --> K3
    VS4 --> K1
    
    PROD1 --> K1
    PROD2 --> K2
    CONS1 --> K2
    CONS2 --> K3
    
    K1 --> ZK1
    K2 --> ZK2
    K3 --> ZK3
    ZK1 -.-> ZK2
    ZK2 -.-> ZK3
    ZK3 -.-> ZK1
    
    VS1 --> PG1
    VS2 --> PG1
    VS3 --> PG2
    VS4 --> PG2
    PG1 --> PG2
    PG1 --> PG3
    
    CONS1 --> ES1
    CONS2 --> ES2
    ES1 -.-> ES2
    ES2 -.-> ES3
    ES3 -.-> ES1
    
    VS1 --> REDIS1
    VS2 --> REDIS1
    VS3 --> REDIS2
    VS4 --> REDIS2
    REDIS1 --> REDIS2
    REDIS1 --> REDIS3
    
    PROM --> API1
    PROM --> API2
    PROM --> API3
    PROM --> VS1
    PROM --> VS2
    PROM --> VS3
    PROM --> VS4
    GRAF --> PROM
    ALERT --> PROM
    
    VOL1 --> VS1
    VOL1 --> VS2
    VOL1 --> VS3
    VOL1 --> VS4
    VOL2 --> PG1
    VOL2 --> PG2
    VOL2 --> PG3
    VOL3 --> ES1
    VOL3 --> ES2
    VOL3 --> ES3
    BACKUP --> VOL1
    BACKUP --> VOL2
    BACKUP --> VOL3
    
    style USER fill:#e3f2fd
    style LB1 fill:#e8f5e8
    style API1 fill:#fff3e0
    style VS1 fill:#fce4ec
    style K1 fill:#f3e5f5
    style PG1 fill:#e0f2f1
    style PROM fill:#fff8e1
```

---

## 🔄 Pipeline de Deployment Automatizado

```mermaid
graph TD
    subgraph "👨‍💻 DEVELOPMENT"
        A[Code Commit]
        B[Local Testing]
        C[Feature Branch]
    end
    
    subgraph "🔄 CI/CD PIPELINE"
        D[GitHub Actions]
        E[Build Images]
        F[Security Scan]
        G[Unit Tests]
        H[Integration Tests]
    end
    
    subgraph "📦 ARTIFACT MANAGEMENT"
        I[Docker Registry]
        J[Helm Charts]
        K[Config Maps]
    end
    
    subgraph "🎭 STAGING DEPLOYMENT"
        L[Deploy Staging]
        M[E2E Tests]
        N[Performance Tests]
        O[User Acceptance]
    end
    
    subgraph "🏭 PRODUCTION DEPLOYMENT"
        P[Blue-Green Deploy]
        Q[Canary Release]
        R[Full Rollout]
    end
    
    subgraph "📊 MONITORING & FEEDBACK"
        S[Health Monitoring]
        T[Performance Metrics]
        U[Error Tracking]
        V[User Feedback]
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    L --> M
    M --> N
    N --> O
    O --> P
    P --> Q
    Q --> R
    R --> S
    S --> T
    T --> U
    U --> V
    
    %% Feedback Loops
    V -.-> A
    U -.-> G
    T -.-> L
    S -.-> P
    
    style A fill:#e3f2fd
    style D fill:#e8f5e8
    style I fill:#fff3e0
    style L fill:#fce4ec
    style P fill:#f3e5f5
    style S fill:#e0f2f1
```

---

## 📊 Matriz de Deployment por Ambiente

```mermaid
graph TB
    subgraph "🏗️ DEPLOYMENT MATRIX"
        subgraph "📱 BASIC (Local)"
            B1[1x API Gateway]
            B2[1x Virtual Stock]
            B3[1x PostgreSQL]
            B4[1x Kafka]
            B5[1x ZooKeeper]
            B6[Basic Monitoring]
        end
        
        subgraph "🧪 TESTING (Free-Tier)"
            T1[1x API Gateway<br/>Limited CPU]
            T2[1x Virtual Stock<br/>512MB RAM]
            T3[1x PostgreSQL<br/>Limited Storage]
            T4[1x Kafka<br/>Single Broker]
            T5[1x ZooKeeper]
            T6[Basic Health Checks]
        end
        
        subgraph "📈 SCALABLE (Simple)"
            S1[2x API Gateway<br/>Load Balanced]
            S2[2x Virtual Stock<br/>1GB RAM each]
            S3[1x PostgreSQL<br/>Master-Replica]
            S4[3x Kafka Brokers<br/>Cluster Mode]
            S5[3x ZooKeeper<br/>Ensemble]
            S6[Prometheus + Grafana]
        end
        
        subgraph "🏢 ENTERPRISE (Full)"
            E1[3x API Gateway<br/>HA + Auto-Scale]
            E2[4x Virtual Stock<br/>2GB RAM each]
            E3[3x PostgreSQL<br/>Master + 2 Replicas]
            E4[3x Kafka Brokers<br/>HA Cluster]
            E5[3x ZooKeeper<br/>Production Ensemble]
            E6[Full Monitoring Stack<br/>Alerting + Tracing]
            E7[HAProxy Load Balancer]
            E8[Elasticsearch Cluster]
            E9[Redis Cache Cluster]
        end
    end
    
    subgraph "📊 RESOURCE ALLOCATION"
        R1[CPU: 2-4 cores<br/>RAM: 2-4GB<br/>Storage: 10-20GB]
        R2[CPU: 4-6 cores<br/>RAM: 4-6GB<br/>Storage: 20-30GB]
        R3[CPU: 8-12 cores<br/>RAM: 8-12GB<br/>Storage: 50-100GB]
        R4[CPU: 16+ cores<br/>RAM: 16+ GB<br/>Storage: 100+ GB]
    end
    
    B1 --> R1
    T1 --> R2
    S1 --> R3
    E1 --> R4
    
    style B1 fill:#e3f2fd
    style T1 fill:#e8f5e8
    style S1 fill:#fff3e0
    style E1 fill:#fce4ec
```

---

## 🚀 Estratégias de Deployment

### 🔵 Blue-Green Deployment

```mermaid
sequenceDiagram
    participant LB as ⚖️ Load Balancer
    participant Blue as 🔵 Blue Environment
    participant Green as 🟢 Green Environment
    participant Monitor as 📊 Monitoring
    participant Ops as 👨‍💻 Operations
    
    Note over Blue: Current Production
    Note over Green: Inactive
    
    Ops->>Green: 🚀 Deploy new version
    Green->>Green: ⚙️ Initialize services
    Green->>Monitor: 📊 Health check
    Monitor->>Ops: ✅ Green environment ready
    
    Ops->>LB: 🔄 Switch traffic to Green
    LB->>Green: 🌊 Route 100% traffic
    
    Monitor->>Green: 📈 Monitor performance
    Green->>Monitor: ✅ All metrics healthy
    
    Note over Blue: Ready for rollback
    Note over Green: New Production
    
    alt Rollback Scenario
        Monitor->>Ops: 🚨 Issues detected
        Ops->>LB: ↩️ Switch back to Blue
        LB->>Blue: 🌊 Route traffic back
        Note over Green: Investigate issues
    end
```

### 🕯️ Canary Deployment

```mermaid
graph TD
    A[🚀 New Version Ready] --> B[Deploy to Canary]
    B --> C[Route 5% Traffic]
    C --> D{Monitor Metrics}
    
    D -->|✅ Healthy| E[Increase to 25%]
    D -->|❌ Issues| F[Rollback Canary]
    
    E --> G{Still Healthy?}
    G -->|✅ Yes| H[Increase to 50%]
    G -->|❌ No| F
    
    H --> I{Performance OK?}
    I -->|✅ Yes| J[Increase to 75%]
    I -->|❌ No| F
    
    J --> K{Final Check}
    K -->|✅ Pass| L[Full Rollout 100%]
    K -->|❌ Fail| F
    
    F --> M[Investigate Issues]
    M --> N[Fix and Retry]
    N --> B
    
    L --> O[🎉 Deployment Complete]
    
    style B fill:#e3f2fd
    style L fill:#c8e6c9
    style F fill:#ffcdd2
```

---

## 🛡️ Disaster Recovery Architecture

```mermaid
graph TB
    subgraph "🏢 PRIMARY DATACENTER"
        subgraph "🏭 Production"
            P1[Application Cluster]
            P2[Database Master]
            P3[Message Brokers]
            P4[Storage Systems]
        end
        
        subgraph "📊 Monitoring"
            M1[Primary Monitoring]
            M2[Health Checks]
            M3[Alert Systems]
        end
    end
    
    subgraph "🏥 DISASTER RECOVERY SITE"
        subgraph "💾 Backup Systems"
            B1[Standby Applications]
            B2[Database Replicas]
            B3[Message Replicas]
            B4[Backup Storage]
        end
        
        subgraph "🚨 Emergency Response"
            E1[DR Monitoring]
            E2[Failover Automation]
            E3[Emergency Contacts]
        end
    end
    
    subgraph "☁️ CLOUD BACKUP"
        C1[Cloud Storage]
        C2[Offsite Backups]
        C3[Archive Systems]
    end
    
    %% Replication
    P1 -.->|Sync| B1
    P2 -.->|Replication| B2
    P3 -.->|Mirror| B3
    P4 -.->|Backup| B4
    
    %% Monitoring
    M1 --> M2
    M2 --> M3
    M3 --> E1
    E1 --> E2
    
    %% Cloud Backup
    P4 -.->|Archive| C1
    B4 -.->|Offsite| C2
    C1 --> C3
    
    %% Failover Process
    E2 -->|Activate| B1
    E2 -->|Promote| B2
    E2 -->|Switch| B3
    E2 -->|Notify| E3
    
    style P1 fill:#e3f2fd
    style B1 fill:#fff3e0
    style E2 fill:#ffcdd2
    style C1 fill:#e8f5e8
```

---

## 📈 Auto-Scaling Architecture

```mermaid
graph TD
    subgraph "📊 METRICS COLLECTION"
        A[CPU Usage]
        B[Memory Usage]
        C[Request Rate]
        D[Response Time]
        E[Error Rate]
    end
    
    subgraph "🎯 SCALING TRIGGERS"
        F[Prometheus Rules]
        G[Alert Manager]
        H[Scaling Controller]
    end
    
    subgraph "⚙️ ORCHESTRATION"
        I[Docker Compose Scale]
        J[Container Management]
        K[Load Balancer Update]
    end
    
    subgraph "🏗️ INFRASTRUCTURE"
        L[Microservice Instances]
        M[Database Connections]
        N[Message Queues]
    end
    
    subgraph "📋 POLICIES"
        O[Scale Up Rules<br/>CPU > 70%<br/>Memory > 80%<br/>Response Time > 2s]
        P[Scale Down Rules<br/>CPU < 30%<br/>Memory < 40%<br/>Low Traffic]
        Q[Limits<br/>Min: 2 instances<br/>Max: 10 instances]
    end
    
    A --> F
    B --> F
    C --> F
    D --> F
    E --> F
    
    F --> G
    G --> H
    H --> I
    
    I --> J
    J --> K
    K --> L
    
    L --> M
    L --> N
    
    O --> H
    P --> H
    Q --> H
    
    style A fill:#e3f2fd
    style F fill:#e8f5e8
    style I fill:#fff3e0
    style L fill:#fce4ec
    style O fill:#c8e6c9
```

---

## 🔍 Monitoring and Observability

```mermaid
graph TB
    subgraph "🎯 APPLICATION LAYER"
        APP1[API Gateway]
        APP2[Virtual Stock Service]
        APP3[Log Producer]
        APP4[Log Consumer]
    end
    
    subgraph "📊 METRICS COLLECTION"
        MICROMETER[Micrometer]
        PROMETHEUS[Prometheus]
        CUSTOM[Custom Metrics]
    end
    
    subgraph "📋 LOGGING"
        LOGBACK[Logback]
        ELASTICSEARCH[Elasticsearch]
        KIBANA[Kibana]
    end
    
    subgraph "🔍 TRACING"
        SLEUTH[Spring Sleuth]
        JAEGER[Jaeger]
        ZIPKIN[Zipkin]
    end
    
    subgraph "📈 VISUALIZATION"
        GRAFANA[Grafana Dashboards]
        ALERTS[Alert Manager]
        NOTIFICATIONS[Slack/Email/PagerDuty]
    end
    
    subgraph "🏥 HEALTH CHECKS"
        ACTUATOR[Spring Actuator]
        HEALTHCHECK[Docker Health Checks]
        LIVENESS[K8s Liveness Probes]
    end
    
    %% Metrics Flow
    APP1 --> MICROMETER
    APP2 --> MICROMETER
    APP3 --> MICROMETER
    APP4 --> MICROMETER
    MICROMETER --> PROMETHEUS
    CUSTOM --> PROMETHEUS
    PROMETHEUS --> GRAFANA
    
    %% Logging Flow
    APP1 --> LOGBACK
    APP2 --> LOGBACK
    APP3 --> LOGBACK
    APP4 --> LOGBACK
    LOGBACK --> ELASTICSEARCH
    ELASTICSEARCH --> KIBANA
    
    %% Tracing Flow
    APP1 --> SLEUTH
    APP2 --> SLEUTH
    APP3 --> SLEUTH
    APP4 --> SLEUTH
    SLEUTH --> JAEGER
    SLEUTH --> ZIPKIN
    
    %% Health Monitoring
    APP1 --> ACTUATOR
    APP2 --> ACTUATOR
    APP3 --> ACTUATOR
    APP4 --> ACTUATOR
    ACTUATOR --> HEALTHCHECK
    HEALTHCHECK --> LIVENESS
    
    %% Alerting
    PROMETHEUS --> ALERTS
    ALERTS --> NOTIFICATIONS
    KIBANA --> ALERTS
    JAEGER --> ALERTS
    
    style APP1 fill:#e3f2fd
    style PROMETHEUS fill:#e8f5e8
    style ELASTICSEARCH fill:#fff3e0
    style JAEGER fill:#fce4ec
    style GRAFANA fill:#f3e5f5
    style ALERTS fill:#ffcdd2
```

---

*Esta documentação apresenta a arquitetura completa de deployment do sistema KBNT Kafka Logs, mostrando todas as estratégias, componentes e fluxos de trabalho implementados para suportar desde desenvolvimento local até produção enterprise de alta disponibilidade.*
