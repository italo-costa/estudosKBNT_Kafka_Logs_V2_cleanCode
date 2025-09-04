# SEQUÊNCIA DE DEPLOYMENT - KBNT Kafka Logs

## Fluxo Completo de Deployment

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as GitHub Repo
    participant Local as Local Env
    participant Test as Test Env
    participant Staging as Staging Env
    participant Prod as Production
    participant Monitor as Monitoring
    
    %% Desenvolvimento Local
    Dev->>Git: git push feature/new-feature
    Git->>Local: Pull latest changes
    Local->>Local: docker-compose up -d
    Local->>Local: Local testing
    
    %% Ambiente de Teste
    Dev->>Test: Deploy to test
    Test->>Test: docker-compose.free-tier.yml up
    Test->>Test: Run integration tests
    Test->>Dev: Test results
    
    %% Merge e Staging
    Dev->>Git: Create pull request
    Git->>Git: Code review
    Git->>Git: Merge to develop
    Git->>Staging: Auto-deploy staging
    Staging->>Staging: docker-compose.scalable-simple.yml up
    Staging->>Monitor: Health metrics
    
    %% Deploy Produção
    Dev->>Git: Create release tag
    Git->>Prod: Deploy production
    Prod->>Prod: docker-compose.scalable.yml up
    Prod->>Prod: Rolling deployment
    Prod->>Monitor: Production metrics
    Monitor->>Dev: Deploy success notification
    
    %% Monitoramento Contínuo
    loop Continuous Monitoring
        Monitor->>Prod: Health checks
        Monitor->>Monitor: Collect metrics
        Monitor->>Dev: Alert if issues
    end
```

---

## Sequência de Inicialização por Ambiente

### Ambiente Local (docker-compose.yml)

```mermaid
sequenceDiagram
    participant User as User
    participant Docker as Docker
    participant PG as PostgreSQL
    participant ZK as ZooKeeper
    participant Kafka as Kafka
    participant VS as Virtual Stock
    participant API as API Gateway
    
    User->>Docker: docker-compose up -d
    Docker->>PG: Start PostgreSQL
    PG->>PG: Initialize database
    Docker->>ZK: Start ZooKeeper
    ZK->>ZK: Initialize cluster
    Docker->>Kafka: Start Kafka
    Kafka->>ZK: Connect to ZooKeeper
    Kafka->>Kafka: Create topics
    Docker->>VS: Start Virtual Stock
    VS->>PG: Connect to database
    VS->>Kafka: Connect to Kafka
    Docker->>API: Start API Gateway
    API->>VS: Register routes
    API->>User: Ready on :8080
```

### Ambiente Escalável (docker-compose.scalable.yml)

```mermaid
sequenceDiagram
    participant User as User
    participant Docker as Docker
    participant PG as PostgreSQL Cluster
    participant ZK as ZooKeeper Cluster
    participant Kafka as Kafka Cluster
    participant ES as Elasticsearch
    participant LB as Load Balancer
    participant Mon as Monitoring
    participant Apps as Microservices
    
    User->>Docker: docker-compose.scalable.yml up -d
    
    par Infrastructure Setup
        Docker->>PG: Start PG Master + Replica
        Docker->>ZK: 🚀 Start ZK Ensemble (3 nodes)
        Docker->>ES: 🚀 Start ES Cluster (2 nodes)
        Docker->>Mon: 🚀 Start Prometheus + Grafana
    end
    
    PG->>PG: 🔄 Setup replication
    ZK->>ZK: 🗳️ Elect leader
    ES->>ES: 🤝 Form cluster
    
    Docker->>Kafka: 🚀 Start Kafka Cluster (3 brokers)
    Kafka->>ZK: 🔗 Register with ZooKeeper
    Kafka->>Kafka: 🔄 Setup partitions & replication
    
    Docker->>LB: 🚀 Start HAProxy
    LB->>LB: 📋 Load balance config
    
    Docker->>Apps: 🚀 Start Multiple App Instances
    
    par Microservices Startup
        Apps->>PG: 🔗 Connect to database
        Apps->>Kafka: 🔗 Connect to brokers
        Apps->>ES: 🔗 Connect for logging
    end
    
    Apps->>LB: 📋 Register with load balancer
    Mon->>Apps: 📊 Start collecting metrics
    LB->>User: ✅ System ready on multiple ports
```

---

## 🔄 Estratégias de Deployment por Complexidade

### 📊 Deployment Progressivo

```mermaid
graph TD
    A[🎯 Start Deployment] --> B{Select Strategy}
    
    %% Nível 1: Básico
    B --> C[📱 Level 1: Basic]
    C --> C1[Single Instance]
    C1 --> C2[docker-compose.yml]
    C2 --> C3[6 Containers]
    C3 --> C4[✅ Basic Setup Complete]
    
    %% Nível 2: Teste
    B --> D[🧪 Level 2: Testing]
    D --> D1[Resource Limited]
    D1 --> D2[docker-compose.free-tier.yml]
    D2 --> D3[8 Containers + Constraints]
    D3 --> D4[✅ Test Environment Ready]
    
    %% Nível 3: Escalável
    B --> E[📈 Level 3: Scalable]
    E --> E1[Multiple Instances]
    E1 --> E2[docker-compose.scalable-simple.yml]
    E2 --> E3[15 Containers + LB]
    E3 --> E4[✅ Production Ready]
    
    %% Nível 4: Enterprise
    B --> F[🏢 Level 4: Enterprise]
    F --> F1[High Availability]
    F1 --> F2[docker-compose.scalable.yml]
    F2 --> F3[36+ Containers + Full HA]
    F3 --> F4[✅ Enterprise Grade]
    
    %% Validação
    C4 --> G[🔍 Validation Phase]
    D4 --> G
    E4 --> G
    F4 --> G
    
    G --> H[Health Checks]
    H --> I[Integration Tests]
    I --> J[Performance Tests]
    J --> K{All Tests Pass?}
    
    K -->|✅ Yes| L[🎉 Deployment Success]
    K -->|❌ No| M[🔧 Troubleshooting]
    M --> N[Fix Issues]
    N --> G
    
    L --> O[📊 Continuous Monitoring]
```

---

## 🎛️ Configuração de Deployment por Ambiente

### 🔧 Matriz de Configuração

```mermaid
graph TB
    subgraph "🎚️ CONFIGURAÇÕES"
        A[Environment Variables]
        B[Resource Limits]
        C[Network Configuration]
        D[Volume Mounts]
        E[Health Checks]
    end
    
    subgraph "🧪 DEVELOPMENT"
        A --> A1[DEBUG=true<br/>LOG_LEVEL=debug<br/>PROFILE=dev]
        B --> B1[CPU: unlimited<br/>Memory: unlimited<br/>Minimal constraints]
        C --> C1[Bridge network<br/>Port mapping<br/>Host networking]
        D --> D1[Local volumes<br/>Hot reload<br/>Source mounts]
        E --> E1[Basic checks<br/>30s intervals<br/>Simple endpoints]
    end
    
    subgraph "🔧 TESTING"
        A --> A2[DEBUG=false<br/>LOG_LEVEL=info<br/>PROFILE=test]
        B --> B2[CPU: 1 core<br/>Memory: 512MB<br/>Strict limits]
        C --> C2[Isolated network<br/>Internal communication<br/>No host access]
        D --> D2[Named volumes<br/>Persistent data<br/>Test fixtures]
        E --> E2[Comprehensive checks<br/>15s intervals<br/>Deep health validation]
    end
    
    subgraph "📈 STAGING"
        A --> A3[DEBUG=false<br/>LOG_LEVEL=warn<br/>PROFILE=staging]
        B --> B3[CPU: 2 cores<br/>Memory: 1GB<br/>Production-like]
        C --> C3[Production network<br/>Load balancing<br/>Service discovery]
        D --> D3[Persistent volumes<br/>Backup enabled<br/>Data replication]
        E --> E3[Production checks<br/>10s intervals<br/>Full monitoring]
    end
    
    subgraph "🏭 PRODUCTION"
        A --> A4[DEBUG=false<br/>LOG_LEVEL=error<br/>PROFILE=prod]
        B --> B4[CPU: 4+ cores<br/>Memory: 2GB+<br/>High limits]
        C --> C4[HA networking<br/>Multiple subnets<br/>Security groups]
        D --> D4[Replicated storage<br/>Automated backup<br/>Disaster recovery]
        E --> E4[Critical checks<br/>5s intervals<br/>Advanced alerting]
    end
    
    style A1 fill:#e3f2fd
    style A2 fill:#e8f5e8
    style A3 fill:#fff3e0
    style A4 fill:#fce4ec
```

---

## 🚀 Processo de CI/CD Pipeline

```mermaid
flowchart LR
    subgraph "👨‍💻 DEVELOPMENT"
        A[Code Changes] --> B[Local Testing]
        B --> C[Git Commit]
        C --> D[Push to Feature Branch]
    end
    
    subgraph "🔄 CONTINUOUS INTEGRATION"
        D --> E[GitHub Actions Trigger]
        E --> F[Build Docker Images]
        F --> G[Run Unit Tests]
        G --> H[Security Scan]
        H --> I[Integration Tests]
    end
    
    subgraph "📋 CODE REVIEW"
        I --> J[Create Pull Request]
        J --> K[Code Review]
        K --> L[Approval Required]
        L --> M[Merge to Develop]
    end
    
    subgraph "🎭 STAGING DEPLOYMENT"
        M --> N[Auto-deploy Staging]
        N --> O[Run E2E Tests]
        O --> P[Performance Tests]
        P --> Q[User Acceptance Tests]
    end
    
    subgraph "🏷️ RELEASE"
        Q --> R[Create Release Tag]
        R --> S[Generate Release Notes]
        S --> T[Deploy to Production]
    end
    
    subgraph "🏭 PRODUCTION"
        T --> U[Blue-Green Deployment]
        U --> V[Health Validation]
        V --> W[Traffic Switch]
        W --> X[Monitor & Alert]
    end
    
    style A fill:#e3f2fd
    style E fill:#e8f5e8
    style J fill:#fff3e0
    style N fill:#f3e5f5
    style R fill:#fce4ec
    style T fill:#ffebee
```

---

## 📊 Monitoramento de Deployment

### 🔍 Health Check Sequence

```mermaid
sequenceDiagram
    participant Deploy as 🚀 Deployment
    participant Container as 📦 Container
    participant Health as 🏥 Health Check
    participant Monitor as 📊 Monitoring
    participant Alert as 🚨 Alerting
    
    Deploy->>Container: Start container
    Container->>Container: Initialize application
    
    loop Health Check Cycle
        Health->>Container: GET /actuator/health
        Container->>Health: Response + Status
        Health->>Monitor: Record metrics
        
        alt Healthy Status
            Monitor->>Monitor: ✅ Update dashboard
        else Unhealthy Status
            Monitor->>Alert: 🚨 Trigger alert
            Alert->>Deploy: 📧 Notify operations team
        end
    end
    
    Note over Health,Monitor: Continuous monitoring<br/>every 10-30 seconds
```

### 📈 Metrics Collection Flow

```mermaid
graph TD
    A[🚀 Application] --> B[📊 Micrometer]
    B --> C[📈 Prometheus]
    C --> D[📊 Grafana Dashboard]
    
    A --> E[📋 Application Logs]
    E --> F[📁 Elasticsearch]
    F --> G[🔍 Kibana]
    
    A --> H[🏥 Health Endpoints]
    H --> I[🔍 Health Checks]
    I --> J[🚨 Alert Manager]
    
    C --> K[📊 Time Series DB]
    K --> L[📈 Historical Analysis]
    
    J --> M[📧 Email Alerts]
    J --> N[📱 Slack Notifications]
    J --> O[🚨 PagerDuty]
    
    style A fill:#e3f2fd
    style C fill:#e8f5e8
    style F fill:#fff3e0
    style J fill:#fce4ec
```

---

## 🛡️ Estratégias de Rollback

```mermaid
flowchart TD
    A[🚨 Deployment Issue Detected] --> B{Issue Severity}
    
    B -->|🟡 Low| C[Minor Issue]
    B -->|🟠 Medium| D[Service Degradation]  
    B -->|🔴 High| E[Critical Failure]
    B -->|⚫ Critical| F[System Outage]
    
    C --> C1[Hot Fix Deployment]
    C1 --> C2[Patch Current Version]
    C2 --> C3[Validate Fix]
    
    D --> D1[Partial Rollback]
    D1 --> D2[Rollback Affected Services]
    D2 --> D3[Maintain Stable Services]
    
    E --> E1[Quick Rollback]
    E1 --> E2[Previous Stable Version]
    E2 --> E3[Emergency Recovery]
    
    F --> F1[Full System Rollback]
    F1 --> F2[Complete Previous State]
    F2 --> F3[Disaster Recovery Mode]
    
    C3 --> G[✅ Resolution Confirmed]
    D3 --> G
    E3 --> G
    F3 --> G
    
    G --> H[📊 Post-Mortem Analysis]
    H --> I[📋 Update Runbooks]
    I --> J[🔄 Improve Process]
    
    style E fill:#ffcdd2
    style F fill:#d32f2f,color:#fff
    style G fill:#c8e6c9
```

---

## 📋 Deployment Checklist Template

### ✅ Pre-Deployment Verification

```mermaid
graph LR
    A[📋 Pre-Deploy Checklist] --> B[Code Quality]
    B --> B1[✅ Tests Passing]
    B --> B2[✅ Code Review Complete]
    B --> B3[✅ Security Scan Clear]
    
    A --> C[Environment Readiness]
    C --> C1[✅ Infrastructure Available]
    C --> C2[✅ Dependencies Updated]
    C --> C3[✅ Configurations Valid]
    
    A --> D[Team Coordination]
    D --> D1[✅ Deployment Window Scheduled]
    D --> D2[✅ Team Notified]
    D --> D3[✅ Rollback Plan Ready]
    
    style B1 fill:#c8e6c9
    style B2 fill:#c8e6c9
    style B3 fill:#c8e6c9
    style C1 fill:#e1f5fe
    style C2 fill:#e1f5fe
    style C3 fill:#e1f5fe
    style D1 fill:#fff3e0
    style D2 fill:#fff3e0
    style D3 fill:#fff3e0
```

---

*Este documento apresenta todas as estratégias e sequências de deployment implementadas no projeto KBNT Kafka Logs, servindo como guia completo para operações de deployment em todos os ambientes.*
