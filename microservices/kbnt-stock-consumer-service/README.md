# KBNT Stock Consumer Service

**Microservice B - Consumer for KBNT Enhanced Kafka Publication Logging System**

## Visão Geral

Este microserviço é responsável por consumir mensagens de atualização de estoque do Red Hat AMQ Streams (Kafka) e processá-las através de APIs externas. Faz parte do sistema completo de logging de publicações Kafka, fornecendo o lado do consumidor do workflow:

**Microservice A (Producer)** → **Red Hat AMQ Streams** → **Microservice B (Consumer)**

## Arquitetura

### Componentes Principais

1. **KafkaConsumerService**: Serviço principal para consumo de mensagens Kafka
2. **ExternalApiService**: Integração com APIs externas para processamento de estoque
3. **ConsumptionLogRepository**: Repositório para logs de auditoria de consumo
4. **MonitoringController**: Endpoints de monitoramento e estatísticas

### Tecnologias

- **Spring Boot 3.2.0**: Framework principal
- **Spring Kafka**: Integração com Kafka/AMQ Streams
- **Spring WebFlux**: Cliente HTTP reativo para APIs externas
- **Spring Data JPA**: Persistência de dados
- **PostgreSQL/H2**: Banco de dados para logs de auditoria
- **Micrometer/Prometheus**: Métricas e monitoramento
- **Testcontainers**: Testes de integração

## Funcionalidades

### Consumo de Mensagens

- **Consumo Multi-Tópico**: Consome de múltiplos tópicos Kafka
- **Processamento Assíncrono**: Processamento não-bloqueante de mensagens
- **Retry Logic**: Mecanismo automático de retry com backoff
- **Dead Letter Topic**: Tratamento de mensagens que falharam após todos os retries

### Validação e Segurança

- **Validação de Hash**: Verificação SHA-256 das mensagens recebidas
- **Detecção de Duplicatas**: Prevenção de reprocessamento de mensagens
- **Verificação de Expiração**: Descarte de mensagens expiradas
- **Auditoria Completa**: Log detalhado de todas as operações

### Integração Externa

- **Validação de Produto**: Verificação de existência do produto
- **Processamento de Estoque**: Chamada para API de atualização de estoque
- **Notificações**: Envio de notificações sobre resultados do processamento
- **Circuit Breaker**: Proteção contra falhas em APIs externas

### Monitoramento

- **Métricas de Performance**: Tempo de processamento, throughput
- **Estatísticas de Consumo**: Sucessos, falhas, taxa de sucesso
- **Health Checks**: Verificação de saúde do aplicativo e dependências
- **Logs Estruturados**: Logging detalhado para troubleshooting

## Configuração

### Variáveis de Ambiente

#### Kafka/AMQ Streams
```bash
KAFKA_BOOTSTRAP_SERVERS=amq-streams-kafka-bootstrap:9092
KAFKA_CONSUMER_GROUP_ID=kbnt-stock-consumer-group
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
KAFKA_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username=\"consumer-user\" password=\"consumer-password\";"
KAFKA_SSL_TRUSTSTORE_LOCATION=/opt/kafka/ssl/truststore.jks
KAFKA_SSL_TRUSTSTORE_PASSWORD=truststore-password
```

#### Banco de Dados
```bash
DB_USERNAME=kbnt_user
DB_PASSWORD=kbnt_password
SPRING_DATASOURCE_URL=jdbc:postgresql://postgresql-service:5432/kbnt_consumption_db
```

#### APIs Externas
```bash
STOCK_SERVICE_URL=http://stock-service:8080
```

### Tópicos Kafka

- `stock-updates`: Tópico principal para atualizações de estoque
- `high-priority-stock-updates`: Tópico para mensagens de alta prioridade
- `stock-updates-retry`: Tópico de retry automático
- `stock-updates-dlt`: Dead Letter Topic para mensagens com falha

## Como Executar

### Desenvolvimento Local

1. **Clone o repositório**:
```bash
git clone <repository-url>
cd microservices/kbnt-stock-consumer-service
```

2. **Configure o banco H2 (desenvolvimento)**:
```bash
# Banco em memória já configurado no application.yml
```

3. **Execute com Maven**:
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=development
```

4. **Acesse os endpoints**:
- Health: http://localhost:8081/api/consumer/actuator/health
- Monitoramento: http://localhost:8081/api/consumer/monitoring/statistics

### Deploy em Produção

1. **Build da aplicação**:
```bash
./scripts/deploy-consumer.sh build
```

2. **Deploy completo**:
```bash
./scripts/deploy-consumer.sh deploy
```

3. **Verificar deployment**:
```bash
./scripts/deploy-consumer.sh verify
```

## Testes

### Executar Testes Unitários
```bash
mvn test
```

### Executar Testes de Integração
```bash
mvn verify -P integration-tests
```

### Cobertura de Testes
```bash
mvn jacoco:report
# Relatório disponível em target/site/jacoco/index.html
```

## APIs de Monitoramento

### Estatísticas de Processamento
```bash
GET /api/consumer/monitoring/statistics?hours=24
```

**Resposta**:
```json
{
  "period_hours": 24,
  "total_messages": 1500,
  "successful_messages": 1450,
  "failed_messages": 50,
  "success_rate_percent": 96.67,
  "average_processing_time_ms": 245.5,
  "generated_at": "2024-01-15T10:30:00"
}
```

### Logs de Consumo
```bash
GET /api/consumer/monitoring/logs?page=0&size=20
```

### Buscar por Correlation ID
```bash
GET /api/consumer/monitoring/logs/correlation/{correlationId}
```

### Operações Mais Lentas
```bash
GET /api/consumer/monitoring/performance/slowest?hours=24&limit=10
```

### Erros de API
```bash
GET /api/consumer/monitoring/errors/api?hours=24
```

## Modelo de Dados

### Consumption Log
```sql
CREATE TABLE consumption_logs (
    id BIGSERIAL PRIMARY KEY,
    correlation_id VARCHAR(100) NOT NULL,
    topic VARCHAR(200) NOT NULL,
    partition_id INTEGER NOT NULL,
    offset_value BIGINT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity INTEGER,
    price DECIMAL(10,2),
    operation VARCHAR(20),
    message_hash VARCHAR(64),
    consumed_at TIMESTAMP NOT NULL,
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    api_call_duration_ms BIGINT,
    api_response_code INTEGER,
    api_response_message VARCHAR(500),
    error_message VARCHAR(1000),
    error_stack_trace VARCHAR(5000),
    retry_count INTEGER DEFAULT 0,
    total_processing_time_ms BIGINT,
    priority VARCHAR(20),
    metadata VARCHAR(2000)
);
```

### Índices para Performance
- `idx_correlation_id` em `correlation_id`
- `idx_consumed_at` em `consumed_at`
- `idx_status` em `status`
- `idx_topic_partition` em `topic, partition_id`

## Métricas e Alertas

### Métricas Prometheus
- `kafka_consumer_messages_total`: Total de mensagens consumidas
- `kafka_consumer_processing_duration_seconds`: Tempo de processamento
- `kafka_consumer_api_calls_total`: Total de chamadas de API
- `kafka_consumer_errors_total`: Total de erros

### Alertas Recomendados
- Taxa de sucesso < 95%
- Tempo médio de processamento > 5 segundos
- Mensagens acumuladas no DLT > 100
- Falhas consecutivas de API > 10

## Troubleshooting

### Problemas Comuns

1. **Mensagens não sendo consumidas**:
   - Verificar conectividade com Kafka
   - Validar configurações de autenticação
   - Verificar se os tópicos existem

2. **Falhas de processamento**:
   - Verificar conectividade com APIs externas
   - Validar formato das mensagens
   - Verificar logs de erro detalhados

3. **Performance lenta**:
   - Aumentar concorrência do consumer
   - Otimizar consultas de banco
   - Verificar timeouts de API

### Comandos de Debug

```bash
# Verificar pods
kubectl get pods -l app=kbnt-stock-consumer-service

# Ver logs detalhados
kubectl logs -f deployment/kbnt-stock-consumer-service

# Verificar métricas
kubectl port-forward svc/kbnt-stock-consumer-service 8081:8081
curl http://localhost:8081/api/consumer/actuator/prometheus

# Executar retry manual
curl -X POST http://localhost:8081/api/consumer/monitoring/retry/{correlationId}
```

## Contribuição

### Estrutura do Projeto
```
src/
├── main/
│   ├── java/
│   │   └── com/estudoskbnt/consumer/
│   │       ├── config/          # Configurações
│   │       ├── controller/      # Controllers REST
│   │       ├── entity/          # Entidades JPA
│   │       ├── model/           # DTOs e modelos
│   │       ├── repository/      # Repositórios JPA
│   │       └── service/         # Serviços de negócio
│   └── resources/
│       └── application.yml      # Configurações da aplicação
└── test/
    ├── java/
    │   └── com/estudoskbnt/consumer/
    │       ├── integration/     # Testes de integração
    │       └── service/         # Testes unitários
    └── resources/
        └── application-test.yml # Configurações de teste
```

### Padrões de Código
- Usar Lombok para reduzir boilerplate
- Documentar métodos públicos com JavaDoc
- Seguir convenções Spring Boot
- Implementar testes para novos recursos

## Roadmap

### Versão 1.1
- [ ] Suporte a Schema Registry
- [ ] Métricas customizadas por produto
- [ ] Dashboard de monitoramento

### Versão 1.2
- [ ] Processamento batch para alta performance
- [ ] Suporte a múltiplos formatos de mensagem
- [ ] Cache distribuído para validações

## Suporte

Para suporte e dúvidas:
- Documentação: [Wiki do Projeto]
- Issues: [GitHub Issues]
- Email: kbnt-support@empresa.com

---

**Autor**: KBNT Development Team  
**Versão**: 1.0.0  
**Última atualização**: 2024-01-15
