# Configuração do Red Hat AMQ Streams para Logs

## Visão Geral

Este documento explica como configurar o Red Hat AMQ Streams especificamente para processamento de logs em um ambiente de estudos.

## 🔴 Sobre o Red Hat AMQ Streams

O AMQ Streams é baseado no projeto open-source **Strimzi** e fornece:
- Apache Kafka com suporte enterprise
- Operadores Kubernetes nativos
- Configuração declarativa via Custom Resources
- Monitoramento e métricas integradas
- Gestão simplificada de clusters Kafka
- **Versão Community gratuita disponível**

## 🎯 Objetivos

- Configurar AMQ Streams para alta performance com logs
- Otimizar retenção e particionamento para dados de log
- Configurar produtores e consumidores eficientes
- Implementar padrões de monitoramento
- Utilizar recursos enterprise na versão community

## 📋 Tópicos Recomendados

### 1. application-logs
**Propósito**: Logs gerais da aplicação
```bash
# Criar tópico
kafka-topics --create --topic application-logs \
  --bootstrap-server localhost:9092 \
  --partitions 6 \
  --replication-factor 3 \
  --config retention.ms=604800000 \
  --config segment.ms=86400000 \
  --config compression.type=snappy
```

**Configurações**:
- **Partições**: 6 (permite 6 consumidores paralelos)
- **Retenção**: 7 dias (604800000 ms)
- **Segmentos**: 1 dia (86400000 ms)
- **Compressão**: Snappy (boa para logs)

### 2. error-logs
**Propósito**: Logs de erro e exceções
```bash
kafka-topics --create --topic error-logs \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 3 \
  --config retention.ms=2592000000 \
  --config min.insync.replicas=2
```

**Configurações**:
- **Retenção**: 30 dias (mais tempo para análise de erros)
- **min.insync.replicas**: 2 (maior durabilidade para erros)

### 3. audit-logs
**Propósito**: Logs de auditoria e segurança
```bash
kafka-topics --create --topic audit-logs \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 3 \
  --config retention.ms=-1 \
  --config cleanup.policy=compact
```

**Configurações**:
- **Retenção**: Infinita (dados de auditoria)
- **Cleanup**: Compact (mantém último valor por chave)

## ⚙️ Configurações do Broker

### server.properties otimizado para logs:

```properties
# Performance para logs
num.network.threads=8
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400

# Configurações de log
log.retention.hours=168
log.retention.bytes=1073741824
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# Compressão padrão
compression.type=snappy

# Auto-criação de tópicos
auto.create.topics.enable=true
num.partitions=3
default.replication.factor=3
```

## 🔧 Configurações de Produtores

### Para Alta Performance:
```python
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    acks='1',  # Apenas leader confirma
    retries=3,
    batch_size=32768,  # Batches maiores para logs
    linger_ms=10,      # Aguarda 10ms para formar batches
    compression_type='snappy',
    buffer_memory=67108864,  # 64MB buffer
)
```

### Para Alta Durabilidade (logs críticos):
```python
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    acks='all',  # Todas réplicas confirmam
    retries=5,
    batch_size=16384,
    linger_ms=5,
    compression_type='gzip',  # Melhor compressão
    enable_idempotence=True,
)
```

## 📥 Configurações de Consumidores

### Consumer Group para Processamento Paralelo:
```python
consumer = KafkaConsumer(
    'application-logs',
    bootstrap_servers=['localhost:9092'],
    group_id='log-processor-group',
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    auto_commit_interval_ms=1000,
    max_poll_records=1000,  # Processa muitos logs por vez
)
```

### Consumer para Análise em Tempo Real:
```python
consumer = KafkaConsumer(
    'error-logs',
    bootstrap_servers=['localhost:9092'],
    group_id='realtime-alert-group',
    auto_offset_reset='latest',  # Apenas novos erros
    enable_auto_commit=False,    # Controle manual
    max_poll_interval_ms=30000,
)
```

## 📊 Particionamento de Logs

### Por Serviço:
```python
# Usa o nome do serviço como chave
key = log_entry['service']
producer.send('application-logs', key=key, value=log_entry)
```

### Por Severidade:
```python
# Particiona por nível de log
if log_entry['level'] == 'ERROR':
    producer.send('error-logs', value=log_entry)
else:
    producer.send('application-logs', value=log_entry)
```

### Por Timestamp:
```python
# Para análise temporal
key = log_entry['timestamp'][:10]  # YYYY-MM-DD
producer.send('application-logs', key=key, value=log_entry)
```

## 🔍 Monitoramento

### Métricas Importantes:

1. **Taxa de Produção**:
   - `kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec`

2. **Taxa de Consumo**:
   - `kafka.consumer:type=consumer-fetch-manager-metrics,client-id=*`

3. **Lag do Consumidor**:
   - `kafka.consumer:type=consumer-fetch-manager-metrics,name=records-lag-max`

4. **Utilização de Disco**:
   - Monitorar `/var/lib/kafka/data`

### Comandos de Monitoramento:

```bash
# Ver todos os tópicos
kafka-topics --list --bootstrap-server localhost:9092

# Detalhes de um tópico
kafka-topics --describe --topic application-logs --bootstrap-server localhost:9092

# Consumer groups
kafka-consumer-groups --list --bootstrap-server localhost:9092

# Lag de um group
kafka-consumer-groups --describe --group log-processor-group --bootstrap-server localhost:9092
```

## 🚨 Alertas e Troubleshooting

### Alertas Importantes:

1. **Disk Usage > 80%**
2. **Consumer Lag > 10000**
3. **Error Rate > 5%**
4. **Partition Leader Changes**

### Comandos de Debug:

```bash
# Ver mensagens de um tópico
kafka-console-consumer --topic application-logs --from-beginning --bootstrap-server localhost:9092

# Resetar offset de consumer group
kafka-consumer-groups --reset-offsets --group my-group --topic application-logs --to-earliest --bootstrap-server localhost:9092

# Ver configurações de um tópico
kafka-configs --describe --entity-type topics --entity-name application-logs --bootstrap-server localhost:9092
```

## 🎯 Próximos Passos

1. [Deploy no Kubernetes](kubernetes-deployment.md)
2. [Integração com ELK Stack](elk-integration.md)
3. [Monitoramento com Grafana](monitoring.md)
4. [Padrões de Logs](logging-patterns.md)
