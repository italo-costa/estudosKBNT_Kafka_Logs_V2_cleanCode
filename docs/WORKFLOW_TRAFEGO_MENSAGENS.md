# 🔄 Workflow de Tráfego de Mensagens - Sistema KBNT Kafka

## 📋 Visão Geral do Fluxo

O sistema implementa um pipeline completo de processamento de logs com arquitetura orientada a eventos, utilizando Apache Kafka como backbone de mensageria.

## 🚀 Etapas Detalhadas do Workflow

### **Etapa 1: Geração e Captura de Logs** 
```
[Aplicação] → [Log Producer Service] → [Validação] → [Serialização]
```

**🛠️ Tecnologias:**
- **Spring Boot 3.2**: Framework principal do Producer Service
- **Logback/SLF4J**: Sistema de logging estruturado
- **Jackson**: Serialização JSON de mensagens
- **Spring Validation**: Validação de dados de entrada

**📝 Processo:**
1. **Aplicação gera evento** (erro, transação, auditoria, etc.)
2. **Producer Service recebe via REST API** (`POST /api/logs`)
3. **Validação de payload** (campos obrigatórios, formato)
4. **Enriquecimento de dados** (timestamp, correlationId, metadados)
5. **Serialização para JSON** estruturado

**💡 Exemplo de Payload:**
```json
{
  "level": "ERROR",
  "message": "Database connection timeout",
  "service": "payment-service",
  "timestamp": "2025-08-29T14:30:45.123Z",
  "correlationId": "uuid-12345",
  "metadata": {
    "userId": "user123",
    "transactionId": "tx456"
  }
}
```

### **Etapa 2: Roteamento Inteligente de Mensagens**
```
[Producer Service] → [Topic Router] → [Kafka Topics]
```

**🛠️ Tecnologias:**
- **Spring Kafka**: Cliente Kafka para Java
- **Apache Kafka**: Plataforma de streaming distribuída
- **Custom Routing Logic**: Algoritmo de roteamento baseado em regras

**📝 Processo:**
1. **Análise do tipo de log** (level, service, categoria)
2. **Aplicação de regras de roteamento:**
   - `ERROR/FATAL` → `error-logs` topic
   - `AUDIT` → `audit-logs` topic  
   - `FINANCIAL` → `financial-logs` topic
   - `INFO/DEBUG/WARN` → `application-logs` topic

**🎯 Configuração de Topics:**
```yaml
Topics:
  application-logs: { partitions: 3, retention: 7d, compression: snappy }
  error-logs: { partitions: 3, retention: 30d, compression: lz4 }
  audit-logs: { partitions: 2, retention: 90d, compression: gzip }
  financial-logs: { partitions: 4, retention: 365d, compression: lz4 }
```

### **Etapa 3: Persistência no Apache Kafka**
```
[Kafka Producer] → [Partition Assignment] → [Kafka Cluster] → [Replication]
```

**🛠️ Tecnologias:**
- **Apache Kafka 2.8+**: Cluster de brokers
- **Apache Zookeeper**: Coordenação de cluster (em transição para KRaft)
- **Kubernetes StatefulSets**: Orquestração de containers persistentes
- **Persistent Volumes**: Armazenamento durável

**📝 Processo:**
1. **Producer envia mensagem** com chave de particionamento
2. **Kafka determina partição** (hash da chave ou round-robin)
3. **Replicação entre brokers** (replication-factor configurável)
4. **Acknowledgment para Producer** (acks=all para durabilidade)
5. **Persistência em disco** com compactação configurada

**⚙️ Configuração de Cluster:**
```yaml
Kafka Cluster:
  Brokers: 3 replicas
  Partitions: 3-4 per topic
  Replication Factor: 2-3
  Min In-Sync Replicas: 2
  Retention: Variable by topic type
```

### **Etapa 4: Consumo e Processamento**
```
[Kafka Consumer] → [Message Processing] → [Business Logic] → [Output Processing]
```

**🛠️ Tecnologias:**
- **Spring Kafka Consumer**: Cliente consumer reativo
- **Spring Boot Actuator**: Monitoramento e health checks
- **Micrometer**: Métricas e observabilidade
- **Circuit Breaker Pattern**: Resiliência contra falhas

**📝 Processo:**
1. **Consumer Group subscription** nos topics relevantes
2. **Polling de mensagens** (batch processing otimizado)
3. **Deserialização JSON** para objetos Java
4. **Processamento de negócio:**
   - **Error Logs**: Alertas, notificações, dashboards
   - **Audit Logs**: Compliance, relatórios de segurança
   - **Financial Logs**: Reconciliação, análise de fraude
   - **Application Logs**: Debugging, performance analysis

### **Etapa 5: Processamento Específico por Tipo**

#### **🚨 Error Logs Processing**
```
[Error Consumer] → [Alert Engine] → [Notification Service] → [Dashboard Update]
```
- **Análise de padrões** de erro
- **Correlação de eventos** relacionados
- **Geração de alertas** automáticos
- **Atualização de dashboards** em tempo real

#### **🔐 Audit Logs Processing** 
```
[Audit Consumer] → [Compliance Engine] → [Security Analysis] → [Report Generation]
```
- **Validação de compliance** (GDPR, SOX, PCI-DSS)
- **Análise de segurança** comportamental
- **Geração de relatórios** regulatórios
- **Armazenamento de longo prazo**

#### **💰 Financial Logs Processing**
```
[Financial Consumer] → [Fraud Detection] → [Reconciliation] → [Reporting]
```
- **Detecção de fraudes** em tempo real
- **Reconciliação automática** de transações
- **Análise de padrões** financeiros
- **Relatórios regulatórios**

### **Etapa 6: Armazenamento e Arquivamento**
```
[Processed Data] → [Database] → [Data Lake] → [Long-term Archive]
```

**🛠️ Tecnologias:**
- **PostgreSQL**: Dados estruturados e consultas complexas
- **Elasticsearch**: Busca full-text e análise de logs
- **Apache Hadoop/S3**: Data lake para big data
- **Apache Parquet**: Formato columnar para analytics

**📝 Processo:**
1. **Armazenamento imediato** em banco relacional
2. **Indexação em Elasticsearch** para busca
3. **ETL para Data Lake** (processamento batch)
4. **Arquivamento** de dados antigos (cold storage)

## 🔧 Tecnologias por Camada

### **🎯 Camada de Aplicação**
```yaml
Microservices:
  - Log Producer Service: Spring Boot 3.2, Java 17
  - Log Consumer Service: Spring Boot 3.2, Java 17
  - API Gateway: Spring Cloud Gateway
  - Configuration Service: Spring Cloud Config
```

### **⚡ Camada de Messaging**
```yaml
Event Streaming:
  - Apache Kafka: Streaming platform
  - Zookeeper: Cluster coordination
  - Kafka Connect: Data integration
  - Schema Registry: Schema evolution
```

### **🏗️ Camada de Infraestrutura**
```yaml
Container Orchestration:
  - Kubernetes: Container orchestration
  - Docker: Containerization
  - Helm Charts: Package management
  - Istio: Service mesh (opcional)

Storage:
  - Persistent Volumes: Kafka data persistence
  - Network File System: Shared storage
  - Backup Solutions: Velero, Restic
```

### **📊 Camada de Observabilidade**
```yaml
Monitoring Stack:
  - Prometheus: Metrics collection
  - Grafana: Visualization dashboards
  - Jaeger: Distributed tracing
  - ELK Stack: Log aggregation and analysis

Health Checks:
  - Spring Actuator: Application health
  - Kubernetes Probes: Container health
  - Custom Health Indicators: Business logic health
```

## 🔄 Padrões de Resiliência Implementados

### **🛡️ Producer Resilience**
- **Retries**: Configuração de tentativas automáticas
- **Circuit Breaker**: Proteção contra cascata de falhas
- **Bulkhead**: Isolamento de recursos críticos
- **Timeout**: Timeouts configuráveis para operações

### **🔄 Consumer Resilience**
- **Dead Letter Queue**: Mensagens com falha de processamento
- **Retry Policy**: Política de reprocessamento
- **Offset Management**: Controle manual de offsets
- **Graceful Shutdown**: Finalização segura de processamento

### **📈 Scalability Patterns**
- **Auto-scaling**: Baseado em lag de consumer
- **Partition Strategy**: Balanceamento de carga
- **Consumer Groups**: Paralelização de processamento
- **Load Balancing**: Distribuição inteligente de carga

## 📊 Métricas e Monitoramento

### **🎯 Métricas Coletadas**
```yaml
Producer Metrics:
  - Messages produced per second
  - Produce latency (p95, p99)
  - Error rate by topic
  - Batch size efficiency

Consumer Metrics:
  - Consumer lag by partition
  - Processing latency
  - Commit frequency
  - Rebalance frequency

Infrastructure Metrics:
  - Kafka broker CPU/Memory
  - Disk I/O utilization
  - Network throughput
  - JVM garbage collection
```

### **🚨 Alerting Rules**
- **High Consumer Lag**: > 10.000 mensagens
- **Producer Error Rate**: > 1% em 5 minutos
- **Broker Down**: Qualquer broker indisponível
- **Disk Usage**: > 85% de utilização

## 🎯 Benefícios da Arquitetura

### **⚡ Performance**
- **Throughput**: 10.000+ mensagens/segundo
- **Latency**: < 100ms end-to-end (p95)
- **Scalability**: Auto-scaling baseado em demanda

### **🛡️ Confiabilidade**
- **Durabilidade**: Replicação multi-broker
- **Availability**: 99.9% uptime target
- **Disaster Recovery**: Backup e restore automático

### **🔧 Operabilidade**
- **Zero-downtime**: Deployment sem interrupção
- **Auto-healing**: Recuperação automática de falhas
- **Monitoring**: Observabilidade completa do pipeline

Este workflow representa um sistema robusto e escalável para processamento de logs em tempo real, com foco em confiabilidade, performance e observabilidade. 🚀
