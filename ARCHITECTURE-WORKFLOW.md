# KBNT Kafka Logs - Complete Application Workflow
# Spring Boot Microservices + Hexagonal Architecture + Red Hat AMQ Streams

## 🏗️ Architecture Overview

### 1. MICROSERVICES LAYER (Spring Boot + Hexagonal Architecture)
```
┌─────────────────────────────────────────────────────────────┐
│                   MICROSERVICES CONTAINERS                  │
├─────────────────────────────────────────────────────────────┤
│  🚀 Stock Producer Service (Port 8080)                     │
│     └── Hexagonal Architecture                             │
│         ├── Domain Layer (Business Logic)                  │
│         ├── Application Layer (Use Cases)                  │
│         ├── Infrastructure Layer (Kafka Producer)          │
│         └── Adapters (REST API, Database)                  │
│                                                             │
│  📊 Stock Consumer Service (Port 8081)                     │
│     └── Hexagonal Architecture                             │
│         ├── Domain Layer (Log Processing)                  │
│         ├── Application Layer (Message Handling)           │
│         ├── Infrastructure Layer (Kafka Consumer)          │
│         └── Adapters (Database, External APIs)             │
│                                                             │
│  📈 KBNT Log Service (Port 8082)                          │
│     └── Hexagonal Architecture                             │
│         ├── Domain Layer (Log Analytics)                   │
│         ├── Application Layer (Log Aggregation)            │
│         ├── Infrastructure Layer (Topic Management)        │
│         └── Adapters (ElasticSearch, Database)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            RED HAT AMQ STREAMS (Kafka Cluster)             │
├─────────────────────────────────────────────────────────────┤
│  🔄 Topics:                                                 │
│     ├── kbnt-application-logs (6 partitions)               │
│     ├── kbnt-error-logs (4 partitions)                     │
│     ├── kbnt-audit-logs (3 partitions)                     │
│     ├── kbnt-financial-logs (8 partitions)                 │
│     └── kbnt-dead-letter-queue (2 partitions)              │
│                                                             │
│  ⚙️ Configuration:                                          │
│     ├── Cluster: 3 Brokers                                 │
│     ├── Replication Factor: 3                              │
│     ├── Retention: 7 days to 365 days                      │
│     └── Compression: snappy/lz4/gzip                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL CONSUMERS                      │
├─────────────────────────────────────────────────────────────┤
│  🐍 Python Log Consumer (Your current file)                │
│  📊 Analytics Dashboard                                     │
│  🔔 Alert Systems                                           │
│  💾 Data Lake Integration                                   │
└─────────────────────────────────────────────────────────────┘

## 🚀 Application Workflow

### Phase 1: Microservice Event Production
1. **Stock Update Event** occurs in business domain
2. **Domain Service** processes business logic (hexagonal core)
3. **Application Service** coordinates the use case
4. **Kafka Adapter** publishes event to AMQ Streams
5. **Infrastructure** handles serialization and delivery

### Phase 2: Message Routing in AMQ Streams
1. **Message arrives** at appropriate topic partition
2. **Red Hat AMQ Streams** handles:
   - Partition assignment
   - Replication across brokers
   - Retention management
   - Compression
3. **Topic configuration** ensures proper message handling

### Phase 3: Consumer Processing
1. **Multiple consumers** subscribe to topics
2. **Python Consumer** (your file) processes logs
3. **Java Consumers** handle business events
4. **Analytics services** aggregate data

## 🛠️ Technology Stack

### Microservices (Containerized)
- Spring Boot 3.x
- Java 17 (OpenJDK)
- Hexagonal Architecture
- Docker containers
- Maven build system

### Message Broker (Separate Environment)
- Red Hat AMQ Streams (Kafka 3.4+)
- Zookeeper cluster
- Strimzi operator (Kubernetes)
- Topic auto-creation
- Message retention policies

### Consumer Applications
- Python kafka-python library
- Java Spring Kafka
- Real-time processing
- Batch analytics

## 📁 Project Structure Mapping

```
microservices/
├── kbnt-log-service/           # Log aggregation microservice
│   ├── src/main/java/.../config/
│   │   └── AmqStreamsTopicConfiguration.java  # Your open file
│   ├── application.yml         # Kafka connection config
│   └── Dockerfile             # Container definition
├── stock-producer-service/     # Business event producer
├── stock-consumer-service/     # Business event consumer
└── docker-compose.yml         # Local container orchestration

kubernetes/
├── amq-streams/               # Red Hat AMQ Streams config
│   ├── kafka-cluster.yaml    # Kafka cluster definition
│   └── kafka-topics.yaml     # Topic configurations
└── microservices/            # K8s deployments

consumers/
└── python/
    └── log-consumer.py       # Your current consumer

scripts/
├── start-complete-environment.ps1  # Full stack startup
└── test-virtual-stock.ps1          # Testing scripts
```
