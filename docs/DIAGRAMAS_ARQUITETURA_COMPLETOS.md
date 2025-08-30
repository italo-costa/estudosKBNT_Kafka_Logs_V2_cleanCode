# Diagramas de Arquitetura Completos

Este documento contém todos os diagramas detalhados da arquitetura do projeto estudosKBNT_Kafka_Logs usando Mermaid.

## 1. Arquitetura Geral com Deployment Kubernetes

```mermaid
graph TB
    subgraph "External World"
        CLIENT[Client Applications<br/>Web/Mobile/APIs]
        EXT_API[External REST API<br/>https://api.external.com<br/>Third-party Integration]
        PROMETHEUS[Prometheus<br/>Monitoring & Alerting<br/>Port: 9090]
    end
    
    subgraph "Kubernetes Cluster"
        subgraph "Namespace: kafka"
            subgraph "Producer Deployment"
                PROD_POD1[log-producer-service-0<br/>Spring Boot 3.2<br/>Hexagonal Architecture<br/>Port: 8081<br/>CPU: 250m Memory: 512Mi]
                PROD_POD2[log-producer-service-1<br/>Spring Boot 3.2<br/>Hexagonal Architecture<br/>Port: 8081<br/>CPU: 250m Memory: 512Mi]
                PROD_POD3[log-producer-service-2<br/>Spring Boot 3.2<br/>Hexagonal Architecture<br/>Port: 8081<br/>CPU: 250m Memory: 512Mi]
            end
            
            subgraph "AMQ Streams Kafka Cluster"
                subgraph "Kafka Topics"
                    T1[application-logs<br/>Partitions: 3<br/>Replication: 2<br/>General application logs]
                    T2[error-logs<br/>Partitions: 3<br/>Replication: 2<br/>Error & Fatal logs]
                    T3[audit-logs<br/>Partitions: 2<br/>Replication: 2<br/>Security & Auth logs]
                    T4[financial-logs<br/>Partitions: 3<br/>Replication: 2<br/>Transaction logs]
                end
                
                subgraph "Kafka Brokers"
                    KAFKA1[kafka-cluster-kafka-0<br/>Port: 9092<br/>CPU: 500m Memory: 1Gi]
                    KAFKA2[kafka-cluster-kafka-1<br/>Port: 9092<br/>CPU: 500m Memory: 1Gi]
                    KAFKA3[kafka-cluster-kafka-2<br/>Port: 9092<br/>CPU: 500m Memory: 1Gi]
                end
            end
            
            subgraph "Consumer Deployment"
                CONS_POD1[log-consumer-service-0<br/>Spring Boot 3.2<br/>API Integration<br/>Port: 8082<br/>CPU: 250m Memory: 512Mi]
                CONS_POD2[log-consumer-service-1<br/>Spring Boot 3.2<br/>API Integration<br/>Port: 8082<br/>CPU: 250m Memory: 512Mi]
            end
            
            subgraph "Zookeeper Cluster"
                ZK1[zookeeper-0<br/>Port: 2181<br/>CPU: 100m-250m Memory: 256Mi-512Mi<br/>Storage: 5Gi data + 5Gi logs]
                ZK2[zookeeper-1<br/>Port: 2181<br/>CPU: 100m-250m Memory: 256Mi-512Mi<br/>Storage: 5Gi data + 5Gi logs]
                ZK3[zookeeper-2<br/>Port: 2181<br/>CPU: 100m-250m Memory: 256Mi-512Mi<br/>Storage: 5Gi data + 5Gi logs]
            end
        end
        
        subgraph "Namespace: monitoring"
            GRAFANA[grafana<br/>Port: 3000<br/>CPU: 200m Memory: 256Mi]
            PROM_SERVER[prometheus-server<br/>Port: 9090<br/>CPU: 500m Memory: 1Gi]
        end
    end
    
    subgraph "Persistent Storage"
        PV1[kafka-data-pvc<br/>Size: 10Gi<br/>AccessMode: RWO]
        PV2[zookeeper-data-pvc<br/>Size: 5Gi<br/>AccessMode: RWO]
        PV3[prometheus-data-pvc<br/>Size: 8Gi<br/>AccessMode: RWO]
    end

    CLIENT -->|HTTP REST| PROD_POD1
    CLIENT -->|HTTP REST| PROD_POD2
    CLIENT -->|HTTP REST| PROD_POD3
    
    PROD_POD1 -->|Produce Messages| T1
    PROD_POD1 -->|Produce Messages| T2
    PROD_POD2 -->|Produce Messages| T3
    PROD_POD3 -->|Produce Messages| T4
    
    T1 --> CONS_POD1
    T2 --> CONS_POD1
    T3 --> CONS_POD2
    T4 --> CONS_POD2
    
    CONS_POD1 -->|HTTP POST| EXT_API
    CONS_POD2 -->|HTTP POST| EXT_API
    
    KAFKA1 <--> ZK1
    KAFKA2 <--> ZK2
    KAFKA3 <--> ZK3
    
    PROD_POD1 -.->|Metrics| PROMETHEUS
    PROD_POD2 -.->|Metrics| PROMETHEUS
    PROD_POD3 -.->|Metrics| PROMETHEUS
    CONS_POD1 -.->|Metrics| PROMETHEUS
    CONS_POD2 -.->|Metrics| PROMETHEUS
    
    PROMETHEUS <--> GRAFANA
    
    KAFKA1 --- PV1
    ZK1 --- PV2
    PROM_SERVER --- PV3

    classDef prodClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef consClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef kafkaClass fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef zkClass fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef monClass fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    
    class PROD_POD1,PROD_POD2,PROD_POD3 prodClass
    class CONS_POD1,CONS_POD2 consClass
    class KAFKA1,KAFKA2,KAFKA3,T1,T2,T3,T4 kafkaClass
    class ZK1,ZK2,ZK3 zkClass
    class PROMETHEUS,PROM_SERVER,GRAFANA monClass
```

## 2. Fluxo de Processamento de Logs - Sequência Completa

```mermaid
sequenceDiagram
    participant C as Client App
    participant LB as Load Balancer
    participant P1 as Producer-1
    participant P2 as Producer-2
    participant KT as Kafka Topics
    participant C1 as Consumer-1
    participant C2 as Consumer-2
    participant API as External API
    participant MON as Monitoring
    
    Note over C,API: Fluxo Síncrono - Produção de Logs
    
    C->>+LB: POST /api/logs (Log Request)
    LB->>+P1: Route to Producer Instance
    
    P1->>P1: Validate Request (Hexagonal)
    P1->>P1: Apply Business Rules
    P1->>P1: Route by Log Level
    
    alt Error/Fatal Logs
        P1->>+KT: Publish to error-logs topic
        KT-->>-P1: Ack (Sync)
    else Audit Logs
        P1->>+KT: Publish to audit-logs topic
        KT-->>-P1: Ack (Sync)
    else Financial Logs
        P1->>+KT: Publish to financial-logs topic
        KT-->>-P1: Ack (Sync)
    else General Logs
        P1->>+KT: Publish to application-logs topic
        KT-->>-P1: Ack (Sync)
    end
    
    P1-->>-LB: 201 Created (Response)
    LB-->>-C: HTTP 201 Success
    
    Note over KT,API: Fluxo Assíncrono - Consumo e Integração
    
    par Consumer 1 Processing
        KT->>+C1: Poll error-logs
        C1->>C1: Process Error Logs
        C1->>+API: POST /alerts (External Integration)
        API-->>-C1: 200 OK
        C1->>+MON: Update Metrics
        
        KT->>+C1: Poll application-logs
        C1->>C1: Process Application Logs
        C1->>+API: POST /logs (External Integration)
        API-->>-C1: 200 OK
    and Consumer 2 Processing
        KT->>+C2: Poll audit-logs
        C2->>C2: Process Audit Logs
        C2->>+API: POST /audit (External Integration)
        API-->>-C2: 200 OK
        C2->>+MON: Update Metrics
        
        KT->>+C2: Poll financial-logs
        C2->>C2: Process Financial Logs
        C2->>+API: POST /transactions (External Integration)
        API-->>-C2: 200 OK
    end
    
    Note over MON: Observabilidade Contínua
    MON->>MON: Aggregate Metrics
    MON->>MON: Generate Alerts
    MON->>MON: Update Dashboards
```

## 3. Arquitetura Hexagonal Interna - Producer Service

```mermaid
graph TB
    subgraph "External Adapters Infrastructure"
        REST[REST Controller<br/>RestController<br/>Port HTTP]
        KAFKA_PROD[Kafka Producer<br/>Service<br/>Port Message]
        METRICS[Metrics Collector<br/>Component<br/>Port Monitoring]
        CONFIG[Configuration<br/>ConfigurationProperties<br/>Port Config]
    end
    
    subgraph "Application Layer"
        subgraph "Use Cases"
            UC1[Process Log Use Case<br/>UseCase<br/>Business Logic]
            UC2[Route Log Use Case<br/>UseCase<br/>Routing Logic]
            UC3[Validate Log Use Case<br/>UseCase<br/>Validation Logic]
        end
        
        subgraph "Application Services"
            AS1[Log Processing Service<br/>ApplicationService<br/>Orchestration]
            AS2[Message Routing Service<br/>ApplicationService<br/>Topic Selection]
        end
    end
    
    subgraph "Domain Layer Core"
        subgraph "Domain Entities"
            ENTITY[LogEntry<br/>id RequestId<br/>level LogLevel<br/>message String<br/>timestamp Instant<br/>serviceName ServiceName<br/>metadata Map]
        end
        
        subgraph "Value Objects"
            VO1[RequestId<br/>value UUID<br/>generate method]
            VO2[LogLevel<br/>INFO WARN ERROR FATAL<br/>isError method]
            VO3[ServiceName<br/>value String<br/>validate method]
        end
        
        subgraph "Domain Services"
            DS1[Log Validation Service<br/>validateLogEntry<br/>validateLevel]
            DS2[Topic Routing Service<br/>determineTopicByLevel<br/>applyRoutingRules]
            DS3[Log Enhancement Service<br/>addTimestamp<br/>addMetadata]
        end
        
        subgraph "Domain Ports Interfaces"
            PORT1[LogRepository<br/>save method<br/>findById method]
            PORT2[MessagePublisher<br/>publish method<br/>publishBatch method]
            PORT3[MetricsCollector<br/>increment method<br/>recordDuration method]
        end
    end
    
    REST -->|HTTP Request| UC1
    UC1 -->|Delegate| AS1
    
    AS1 -->|Use| DS1
    AS1 -->|Use| DS2
    AS1 -->|Use| DS3
    AS1 -->|Create| ENTITY
    
    UC2 -->|Route Decision| DS2
    UC3 -->|Validate| DS1
    
    ENTITY -->|Contains| VO1
    ENTITY -->|Contains| VO2
    ENTITY -->|Contains| VO3
    
    DS1 -->|Validates| ENTITY
    DS2 -->|Routes| ENTITY
    DS3 -->|Enhances| ENTITY
    
    AS1 -->|Call| PORT2
    AS2 -->|Call| PORT3
    UC1 -->|Store| PORT1
    
    KAFKA_PROD -.->|Implements| PORT2
    METRICS -.->|Implements| PORT3
    CONFIG -.->|Provides| AS1
    
    classDef domainClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:3px
    classDef appClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef infraClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef portClass fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,stroke-dasharray: 5 5
    
    class ENTITY,VO1,VO2,VO3,DS1,DS2,DS3 domainClass
    class UC1,UC2,UC3,AS1,AS2 appClass
    class REST,KAFKA_PROD,METRICS,CONFIG infraClass
    class PORT1,PORT2,PORT3 portClass
```

## 4. Estratégia de Roteamento de Tópicos

```mermaid
flowchart TD
    START([Log Entry Received]) --> VALIDATE{Validate Entry?}
    
    VALIDATE -->|Invalid| REJECT[Reject Request<br/>Return 400 Bad Request]
    VALIDATE -->|Valid| EXTRACT[Extract Log Level<br/>& Service Name]
    
    EXTRACT --> ROUTE_DECISION{Route by Level}
    
    ROUTE_DECISION -->|ERROR/FATAL| ERROR_TOPIC[error-logs Topic<br/>Partitions: 3<br/>Replication: 2<br/>Retention: 7 days<br/>High Priority Queue]
    
    ROUTE_DECISION -->|INFO/DEBUG/TRACE| CHECK_SERVICE{Check Service Type}
    
    CHECK_SERVICE -->|audit-service<br/>auth-service<br/>security-service| AUDIT_TOPIC[audit-logs Topic<br/>Partitions: 2<br/>Replication: 2<br/>Retention: 30 days<br/>Compliance Required]
    
    CHECK_SERVICE -->|payment-service<br/>transaction-service<br/>billing-service| FINANCIAL_TOPIC[financial-logs Topic<br/>Partitions: 3<br/>Replication: 2<br/>Retention: 90 days<br/>Regulatory Compliance]
    
    CHECK_SERVICE -->|Other Services| APP_TOPIC[application-logs Topic<br/>Partitions: 3<br/>Replication: 2<br/>Retention: 3 days<br/>General Purpose]
    
    ERROR_TOPIC --> ERROR_CONSUMER[Error Consumer<br/>Real-time Alerts<br/>Incident Management<br/>Auto-scaling Trigger]
    
    AUDIT_TOPIC --> AUDIT_CONSUMER[Audit Consumer<br/>Compliance Reporting<br/>Security Analysis<br/>Long-term Storage]
    
    FINANCIAL_TOPIC --> FINANCIAL_CONSUMER[Financial Consumer<br/>Transaction Monitoring<br/>Fraud Detection<br/>Regulatory Reporting]
    
    APP_TOPIC --> APP_CONSUMER[Application Consumer<br/>Performance Monitoring<br/>Usage Analytics<br/>General Logging]
    
    ERROR_CONSUMER --> EXTERNAL_ALERTS[External Alert System<br/>PagerDuty/Slack<br/>Immediate Notification]
    
    AUDIT_CONSUMER --> EXTERNAL_COMPLIANCE[Compliance System<br/>Audit Trail Storage<br/>Regulatory Reports]
    
    FINANCIAL_CONSUMER --> EXTERNAL_FINANCE[Financial System<br/>Transaction Processing<br/>Risk Management]
    
    APP_CONSUMER --> EXTERNAL_ANALYTICS[Analytics Platform<br/>Business Intelligence<br/>Performance Metrics]
    
    classDef topicClass fill:#fff2cc,stroke:#d6b656,stroke-width:2px
    classDef consumerClass fill:#d5e8d4,stroke:#82b366,stroke-width:2px
    classDef externalClass fill:#f8cecc,stroke:#b85450,stroke-width:2px
    classDef decisionClass fill:#e1d5e7,stroke:#9673a6,stroke-width:2px
    
    class ERROR_TOPIC,AUDIT_TOPIC,FINANCIAL_TOPIC,APP_TOPIC topicClass
    class ERROR_CONSUMER,AUDIT_CONSUMER,FINANCIAL_CONSUMER,APP_CONSUMER consumerClass
    class EXTERNAL_ALERTS,EXTERNAL_COMPLIANCE,EXTERNAL_FINANCE,EXTERNAL_ANALYTICS externalClass
    class VALIDATE,ROUTE_DECISION,CHECK_SERVICE decisionClass
```

## 5. Monitoramento e Observabilidade

```mermaid
graph TB
    subgraph "Application Metrics"
        subgraph "Producer Metrics"
            PM1[Request Count<br/>Counter: http_requests_total<br/>Labels: method,status,endpoint]
            PM2[Request Duration<br/>Histogram: http_request_duration_seconds<br/>Buckets: 0.1,0.5,1,5,10]
            PM3[Kafka Messages Sent<br/>Counter: kafka_messages_sent_total<br/>Labels: topic,partition]
            PM4[Kafka Send Duration<br/>Histogram: kafka_send_duration_seconds<br/>Buckets: 0.001,0.01,0.1,1]
        end
        
        subgraph "Consumer Metrics"
            CM1[Messages Consumed<br/>Counter: kafka_messages_consumed_total<br/>Labels: topic,partition,consumer_group]
            CM2[Processing Duration<br/>Histogram: message_processing_duration_seconds<br/>Buckets: 0.1,0.5,1,5,10]
            CM3[External API Calls<br/>Counter: external_api_calls_total<br/>Labels: endpoint,status]
            CM4[Consumer Lag<br/>Gauge: kafka_consumer_lag<br/>Labels: topic,partition,consumer_group]
        end
    end
    
    subgraph "Infrastructure Metrics"
        subgraph "Kafka Metrics"
            KM1[Broker Disk Usage<br/>Gauge: kafka_broker_disk_usage_bytes<br/>Labels: broker_id]
            KM2[Topic Partition Count<br/>Gauge: kafka_topic_partition_count<br/>Labels: topic]
            KM3[Under Replicated Partitions<br/>Gauge: kafka_under_replicated_partitions<br/>Labels: broker_id]
            KM4[Messages Per Second<br/>Rate: kafka_messages_per_second<br/>Labels: topic,partition]
        end
        
        subgraph "Kubernetes Metrics"
            K8M1[Pod CPU Usage<br/>Gauge: container_cpu_usage_seconds_total<br/>Labels: pod,container]
            K8M2[Pod Memory Usage<br/>Gauge: container_memory_usage_bytes<br/>Labels: pod,container]
            K8M3[Pod Restart Count<br/>Counter: kube_pod_container_status_restarts_total<br/>Labels: pod,container]
            K8M4[Service Endpoints<br/>Gauge: kube_service_info<br/>Labels: service,namespace]
        end
    end
    
    subgraph "Alerting Rules"
        subgraph "Critical Alerts"
            A1[High Error Rate<br/>Alert: error_rate > 5%<br/>For: 5m<br/>Severity: critical]
            A2[Consumer Lag High<br/>Alert: kafka_consumer_lag > 1000<br/>For: 10m<br/>Severity: critical]
            A3[Pod Memory High<br/>Alert: memory_usage > 80%<br/>For: 15m<br/>Severity: warning]
        end
        
        subgraph "Warning Alerts"
            A4[Response Time High<br/>Alert: response_time > 2s<br/>For: 10m<br/>Severity: warning]
            A5[Disk Usage High<br/>Alert: disk_usage > 75%<br/>For: 30m<br/>Severity: warning]
            A6[Kafka Broker Down<br/>Alert: kafka_broker_up == 0<br/>For: 1m<br/>Severity: critical]
        end
    end
    
    subgraph "Dashboards"
        subgraph "Application Dashboard"
            D1[Request Rate & Latency<br/>Panels: Time Series<br/>Queries: Prometheus PromQL]
            D2[Error Rate & Status Codes<br/>Panels: Stat & Bar Chart<br/>Thresholds: Green/Yellow/Red]
            D3[Kafka Producer Performance<br/>Panels: Graph & Heatmap<br/>Metrics: Send Rate & Duration]
        end
        
        subgraph "Infrastructure Dashboard"
            D4[Kafka Cluster Health<br/>Panels: Status & Topology<br/>Metrics: Broker Status & Partition Health]
            D5[Kubernetes Resources<br/>Panels: Resource Usage<br/>Metrics: CPU/Memory/Storage per Pod]
            D6[Consumer Group Status<br/>Panels: Lag & Throughput<br/>Metrics: Consumer Performance]
        end
    end
    
    subgraph "Data Flow"
        APPS[Microservices<br/>Producer & Consumer] -->|Metrics Export| PROMETHEUS_MAIN[Prometheus Server<br/>Scrape Interval: 15s<br/>Retention: 15d]
        
        KAFKA_EXPORTER[Kafka Exporter<br/>JMX Metrics Collection] -->|Kafka Metrics| PROMETHEUS_MAIN
        
        KUBE_STATE[kube-state-metrics<br/>Kubernetes API Metrics] -->|K8s Metrics| PROMETHEUS_MAIN
        
        NODE_EXPORTER[node-exporter<br/>System Metrics] -->|Node Metrics| PROMETHEUS_MAIN
        
        PROMETHEUS_MAIN -->|Query| GRAFANA_MAIN[Grafana<br/>Visualization & Dashboards]
        PROMETHEUS_MAIN -->|Evaluate| ALERTMANAGER[AlertManager<br/>Alert Routing & Notification]
        
        ALERTMANAGER -->|Notify| SLACK[Slack Integration<br/>Channel: alerts]
        ALERTMANAGER -->|Notify| EMAIL[Email Notifications<br/>On-call Team]
        ALERTMANAGER -->|Notify| PAGERDUTY[PagerDuty<br/>Incident Management]
    end
    
    classDef metricsClass fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef alertClass fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef dashClass fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef flowClass fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class PM1,PM2,PM3,PM4,CM1,CM2,CM3,CM4,KM1,KM2,KM3,KM4,K8M1,K8M2,K8M3,K8M4 metricsClass
    class A1,A2,A3,A4,A5,A6 alertClass
    class D1,D2,D3,D4,D5,D6 dashClass
    class APPS,PROMETHEUS_MAIN,GRAFANA_MAIN,ALERTMANAGER,SLACK,EMAIL,PAGERDUTY flowClass
```

---

## Resumo Técnico

### Tecnologias Utilizadas
- **Spring Boot 3.2** - Framework de microserviços
- **AMQ Streams (Apache Kafka)** - Streaming de mensagens
- **Kubernetes** - Orquestração de contêineres
- **Prometheus + Grafana** - Monitoramento e observabilidade
- **Mermaid** - Diagramação como código

### Padrões Arquiteturais
- **Hexagonal Architecture** - Isolamento de domínio
- **CQRS Pattern** - Separação de leitura e escrita
- **Event-Driven Architecture** - Comunicação assíncrona
- **Circuit Breaker Pattern** - Resiliência de integração

### Características Principais
- **Escalabilidade Horizontal** - Pods com auto-scaling
- **Alta Disponibilidade** - Réplicas múltiplas e failover
- **Observabilidade Completa** - Métricas, logs e traces
- **Integração Externa** - APIs REST para third-party systems

Este documento serve como referência completa para a arquitetura do sistema de logs distribuídos.
