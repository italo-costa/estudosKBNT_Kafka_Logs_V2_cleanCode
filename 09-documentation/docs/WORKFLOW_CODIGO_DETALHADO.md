# 🔄 Workflow Detalhado - Sistema KBNT Log Service

Baseado na análise completa do código, aqui está o workflow detalhado do sistema com foco nas mensagens e tecnologias utilizadas.

## 📋 **Estrutura da Mensagem (LogMessage)**

### **🎯 Modelo Unificado de Dados**
```java
@Data
@Builder
public class LogMessage {
    @NotBlank private String level;          // DEBUG, INFO, WARN, ERROR, FATAL
    @NotBlank private String message;        // Conteúdo da mensagem
    private String serviceName;              // Nome do serviço origem
    private String category;                 // APPLICATION, ERROR, AUDIT, FINANCIAL
    private LocalDateTime timestamp;         // Timestamp ISO 8601
    private String correlationId;            // ID para rastreamento
    private String userId;                   // ID do usuário (auditoria)
    private String sessionId;                // ID da sessão
    private String requestId;                // ID da requisição
    private ExceptionInfo exception;         // Informações de exceção
    private Map<String, Object> metadata;   // Metadados adicionais
    private String environment;             // dev, test, prod
    private String version;                 // Versão da aplicação
    private String hostname;                // Host/pod de origem
}
```

**🔧 Tecnologias de Serialização:**
- **Jackson**: Serialização/deserialização JSON
- **Bean Validation**: Validação com `@NotBlank`, `@NotNull`
- **Lombok**: Redução de boilerplate code
- **Java Time API**: Timestamps precisos com `LocalDateTime`

---

## 🚀 **Etapa 1: Recepção de Mensagens**

### **📡 Controller REST Unificado**
```java
@RestController
@RequestMapping("/api/v1/logs")
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
public class UnifiedLogController {
    
    // Endpoints disponíveis:
    // POST /api/v1/logs              -> Roteamento automático
    // POST /api/v1/logs/application  -> Logs de aplicação
    // POST /api/v1/logs/error        -> Logs de erro
    // POST /api/v1/logs/audit        -> Logs de auditoria
    // POST /api/v1/logs/financial    -> Logs financeiros
    // POST /api/v1/logs/batch        -> Processamento em lote
}
```

**🛠️ Tecnologias:**
- **Spring Boot 3.2**: Framework web reativo
- **Spring Web MVC**: Controllers REST
- **Bean Validation**: Validação automática de payloads
- **Micrometer**: Métricas com `@Timed`
- **CompletableFuture**: Processamento assíncrono

**📝 Fluxo de Processamento:**
1. **Recepção HTTP**: Cliente envia POST com LogMessage JSON
2. **Validação**: Spring valida campos obrigatórios (`@Valid`)
3. **Header Processing**: Extrai `X-Correlation-ID` se presente
4. **Enriquecimento**: Adiciona metadados automaticamente
5. **Resposta Assíncrona**: Retorna `CompletableFuture<ResponseEntity>`

---

## ⚙️ **Etapa 2: Processamento e Enriquecimento**

### **🔧 Unified Log Producer**
```java
@Service
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
public class UnifiedLogProducer {
    
    private void enrichLogMessage(LogMessage logMessage) {
        // Auto-timestamp se não fornecido
        if (logMessage.getTimestamp() == null) {
            logMessage.setTimestamp(LocalDateTime.now());
        }
        
        // UUID para correlação se não fornecido
        if (logMessage.getCorrelationId() == null) {
            logMessage.setCorrelationId(UUID.randomUUID().toString());
        }
        
        // Service name padrão
        if (logMessage.getServiceName() == null) {
            logMessage.setServiceName("kbnt-log-service");
        }
    }
}
```

**🎯 Algoritmo de Roteamento Inteligente:**
```java
private String determineTargetTopic(LogMessage logMessage) {
    String level = logMessage.getLevel().toUpperCase();
    String category = logMessage.getCategory();
    
    // 1. PRIORIDADE: Logs Financeiros
    if ("FINANCIAL".equalsIgnoreCase(category) || 
        message.contains("transaction") || message.contains("payment")) {
        return financialLogsTopic; // kbnt-financial-logs
    }
    
    // 2. Logs de Auditoria
    if ("AUDIT".equalsIgnoreCase(category) || 
        message.contains("audit") || message.contains("security")) {
        return auditLogsTopic; // kbnt-audit-logs
    }
    
    // 3. Logs de Erro (ERROR/FATAL)
    if ("ERROR".equals(level) || "FATAL".equals(level)) {
        return errorLogsTopic; // kbnt-error-logs
    }
    
    // 4. PADRÃO: Logs de Aplicação
    return applicationLogsTopic; // kbnt-application-logs
}
```

---

## 🏗️ **Etapa 3: Topics AMQ Streams**

### **📋 Configuração Diferenciada por Tipo**

#### **🔹 Application Logs Topic**
```yaml
name: kbnt-application-logs
partitions: 6        # Alto throughput
replicas: 3          # Disponibilidade
retention: 7 days    # Curto prazo
compression: snappy  # Performance
max.message: 1MB     # Mensagens médias
```

#### **🚨 Error Logs Topic**
```yaml
name: kbnt-error-logs  
partitions: 4        # Processamento focado
retention: 30 days   # Retenção estendida
compression: lz4     # Melhor compressão
max.message: 2MB     # Stack traces grandes
min.insync: 2        # Consistência
```

#### **🔐 Audit Logs Topic**
```yaml
name: kbnt-audit-logs
partitions: 3        # Processamento sequencial
retention: 90 days   # Compliance
compression: gzip    # Máxima compressão
segment: 2 hours     # Arquivamento frequente
```

#### **💰 Financial Logs Topic**
```yaml
name: kbnt-financial-logs
partitions: 8        # Máxima paralelização  
retention: 365 days  # Regulamentação
compression: lz4     # Balance performance/compressão
min.insync: 3        # Máxima consistência
```

**🛠️ Tecnologias AMQ Streams:**
- **Strimzi Operator**: Gerenciamento declarativo do Kafka
- **Kafka CRDs**: Definição de topics via Kubernetes
- **Red Hat AMQ Streams**: Plataforma empresarial Kafka
- **OpenShift/Kubernetes**: Orquestração de containers

---

## 🔄 **Etapa 4: Modos de Execução Configuráveis**

### **⚙️ Processing Mode Configuration**
```java
@Configuration
public class ProcessingModeConfiguration {
    
    @Value("${app.processing.modes:producer,consumer,processor}")
    private String processingModes;
    
    // Métodos de controle:
    public boolean isProducerModeEnabled()  // REST API ativa
    public boolean isConsumerModeEnabled()  // Kafka consumers ativos  
    public boolean isProcessorModeEnabled() // Business logic ativa
}
```

### **🎛️ Configurações Condicionais**
```java
// Producer Mode - Apenas quando "producer" está ativo
@Configuration
@ConditionalOnProperty(value = "app.processing.modes", havingValue = "producer")
class ProducerModeConfiguration { }

// Consumer Mode - Apenas quando "consumer" está ativo  
@Configuration
@ConditionalOnProperty(value = "app.processing.modes", havingValue = "consumer")
class ConsumerModeConfiguration { }

// Processor Mode - Apenas quando "processor" está ativo
@Configuration
@ConditionalOnProperty(value = "app.processing.modes", havingValue = "processor") 
class ProcessorModeConfiguration { }
```

**🔧 Cenários de Deployment:**
```bash
# Cenário 1: Servidor completo
APP_PROCESSING_MODES=producer,consumer,processor

# Cenário 2: Apenas API (scale horizontal)
APP_PROCESSING_MODES=producer

# Cenário 3: Apenas processamento (scale vertical)
APP_PROCESSING_MODES=consumer,processor

# Cenário 4: Worker dedicado
APP_PROCESSING_MODES=processor
```

---

## 📊 **Etapa 5: Particionamento e Performance**

### **🎯 Estratégia de Particionamento**
```java
private String generatePartitionKey(LogMessage logMessage) {
    // Chave composta: serviço + nível
    return String.format("%s-%s", 
        logMessage.getServiceName() != null ? logMessage.getServiceName() : "unknown",
        logMessage.getLevel());
}
```

**📈 Distribuição de Carga:**
- **Application Logs**: 6 partitions → ~16% cada
- **Error Logs**: 4 partitions → 25% cada
- **Audit Logs**: 3 partitions → ~33% cada  
- **Financial Logs**: 8 partitions → 12.5% each

### **⚡ Configurações de Performance**
```yaml
spring:
  kafka:
    producer:
      acks: all                    # Máxima durabilidade
      retries: 3                   # Retry automático
      batch-size: 16384           # 16KB batches
      linger-ms: 10               # Micro-batching
      buffer-memory: 33554432     # 32MB buffer
      compression-type: snappy     # Performance
      enable.idempotence: true     # Exactly-once semantics
      
    consumer:
      group-id: kbnt-log-consumer-group
      auto-offset-reset: earliest  # Processa todas as mensagens
      enable-auto-commit: false    # Controle manual de offsets
      max-poll-records: 500        # Batch processing
      session-timeout-ms: 30000    # Detecção de falhas
```

---

## 🛡️ **Etapa 6: Resiliência e Observabilidade**

### **🔧 Circuit Breaker Pattern**
```yaml
app:
  circuit-breaker:
    enabled: true
    failure-rate-threshold: 60    # 60% falhas
    wait-duration-in-open-state: 30s
    sliding-window-size: 10
    minimum-number-of-calls: 5
```

### **📈 Métricas Integradas**
```java
@Timed(value = "log.produce", description = "Time taken to produce log messages")
public CompletableFuture<ResponseEntity<Map<String, Object>>> produceLog() {
    // Métricas automáticas:
    // - log_produce_duration_seconds
    // - log_produce_total
    // - kafka_producer_messages_sent_total
    // - kafka_consumer_lag_by_partition
}
```

**🏥 Health Checks:**
```yaml
management:
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
  # Endpoints disponíveis:
  # /actuator/health        - Status geral
  # /actuator/health/kafka  - Status Kafka específico
  # /actuator/metrics       - Métricas Prometheus
  # /actuator/prometheus    - Métricas formatted
```

---

## 🚀 **Tecnologias Utilizadas - Stack Completo**

### **🎯 Application Layer**
- **Spring Boot 3.2**: Framework principal
- **Spring Kafka**: Integração Kafka nativa
- **Spring Web**: REST controllers
- **Spring Actuator**: Observabilidade
- **Jackson**: Serialização JSON
- **Bean Validation**: Validação de dados
- **Lombok**: Redução de boilerplate

### **⚡ Messaging Layer**  
- **Red Hat AMQ Streams**: Kafka empresarial
- **Strimzi Operator**: Gerenciamento declarativo
- **Apache Kafka 3.4**: Message streaming
- **Zookeeper**: Coordenação de cluster

### **🏗️ Infrastructure Layer**
- **Kubernetes/OpenShift**: Orquestração
- **Docker**: Containerização
- **Helm**: Package management
- **Persistent Volumes**: Storage durável

### **📊 Observability Stack**
- **Micrometer**: Métricas
- **Prometheus**: Coleta de métricas
- **Grafana**: Dashboards (implícito)
- **Logstash Encoder**: Structured logging
- **Resilience4j**: Circuit breaker

---

## 🎯 **Fluxo Completo - Exemplo Prático**

### **📤 Request Example**
```bash
curl -X POST http://kbnt-log-service:8080/api/v1/logs \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: txn-12345" \
  -d '{
    "level": "ERROR",
    "message": "Payment processing failed for transaction",
    "serviceName": "payment-service",
    "category": "FINANCIAL",
    "userId": "user123",
    "metadata": {
      "transactionId": "txn-12345",
      "amount": 150.00,
      "currency": "USD"
    }
  }'
```

### **🔄 Processing Flow**
1. **Controller** recebe POST → valida payload
2. **Producer** enriquece mensagem → adiciona timestamp, correlationId
3. **Router** determina topic → `kbnt-financial-logs` (categoria FINANCIAL)
4. **Kafka Producer** envia → partition calculada por `payment-service-ERROR`
5. **AMQ Streams** persiste → replication factor 3, compression lz4
6. **Response** retorna → HTTP 202 com metadata do Kafka

### **📥 Response Example**
```json
{
  "status": "accepted",
  "correlationId": "txn-12345",
  "topic": "kbnt-financial-logs",
  "partition": 2,
  "offset": 12847
}
```

Este workflow representa um sistema **enterprise-grade** para processamento de logs com **alta disponibilidade**, **performance otimizada** e **observabilidade completa**! 🚀
