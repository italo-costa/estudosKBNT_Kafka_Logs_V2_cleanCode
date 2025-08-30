# Red Hat AMQ Streams - Requisitos de Ambiente

## 📋 Visão Geral
Red Hat AMQ Streams é a distribuição enterprise do Apache Kafka fornecida pela Red Hat, baseada no projeto Strimzi para Kubernetes/OpenShift.

## 🎯 Opções de Deployment

### 1. Red Hat AMQ Streams no OpenShift/Kubernetes
**Recomendado para Produção Enterprise**

#### Requisitos Mínimos:
- **OpenShift 4.8+** ou **Kubernetes 1.21+**
- **3+ nós** para alta disponibilidade
- **8GB RAM** por nó mínimo
- **100GB storage** persistente por broker
- **Red Hat subscription** ativa

#### Componentes Principais:
```yaml
# Cluster Operator
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kbnt-kafka-cluster
spec:
  kafka:
    version: 3.4.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    storage:
      type: persistent-claim
      size: 100Gi
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 10Gi
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

### 2. Red Hat AMQ Streams Standalone (Não-Kubernetes)
**Para Desenvolvimento e Testes**

#### Requisitos:
- **RHEL 8/9** ou **CentOS Stream**
- **Java 11** ou **Java 17**
- **4GB RAM** mínimo
- **50GB storage**
- **Red Hat subscription** para downloads oficiais

#### Estrutura de Diretórios:
```
/opt/amq-streams/
├── bin/           # Scripts de inicialização
├── config/        # Configurações
├── libs/          # Bibliotecas Java
└── logs/          # Logs do sistema
```

### 3. Apache Kafka Open Source (Alternativa Gratuita)
**Para Desenvolvimento Local**

#### Vantagens:
- ✅ **Gratuito** e open source
- ✅ **Compatível** com AMQ Streams
- ✅ **Fácil instalação** local
- ✅ **Mesmo protocolo** e APIs

#### Desvantagens vs AMQ Streams:
- ❌ Sem suporte enterprise Red Hat
- ❌ Sem ferramentas de gerenciamento avançadas
- ❌ Sem integração nativa OpenShift
- ❌ Configuração manual necessária

## 🚀 Opções de Setup para o Projeto KBNT

### Opção 1: AMQ Streams no OpenShift (Produção)
```bash
# 1. Instalar AMQ Streams Operator
oc apply -f https://operatorhub.io/install/amq-streams.yaml

# 2. Criar namespace
oc new-project kbnt-kafka

# 3. Deploy do cluster Kafka
oc apply -f kafka-cluster.yaml

# 4. Verificar status
oc get kafka kbnt-kafka-cluster -o yaml
```

### Opção 2: Kafka Docker Compose (Desenvolvimento)
```yaml
# docker-compose-kafka.yml
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    ports:
      - "9092:9092"
```

### Opção 3: Kafka Local (Desenvolvimento Simples)
```powershell
# Download Apache Kafka
wget https://downloads.apache.org/kafka/2.13-3.4.0/kafka_2.13-3.4.0.tgz

# Extrair
tar -xzf kafka_2.13-3.4.0.tgz

# Iniciar Zookeeper
bin/zookeeper-server-start.sh config/zookeeper.properties

# Iniciar Kafka
bin/kafka-server-start.sh config/server.properties
```

## 🔧 Configuração para Microserviços Spring Boot

### application.yml dos Microserviços:
```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
    consumer:
      group-id: ${spring.application.name}
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

### Tópicos Necessários para KBNT:
```bash
# Criar tópicos
kafka-topics.sh --create --topic user-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics.sh --create --topic order-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics.sh --create --topic payment-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics.sh --create --topic inventory-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics.sh --create --topic notification-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics.sh --create --topic audit-logs --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

## 🎯 Recomendação para o Projeto Atual

### Para Desenvolvimento (Fase Atual):
1. **Apache Kafka via Docker Compose** 
   - Rápido de configurar
   - Compatível com AMQ Streams
   - Permite testar todos os recursos

### Para Produção (Futuro):
1. **Red Hat AMQ Streams no OpenShift**
   - Suporte enterprise
   - Alta disponibilidade
   - Monitoramento avançado

## 📦 Scripts de Setup Automático

### setup-kafka-docker.ps1:
```powershell
# Baixar e iniciar Kafka via Docker
docker-compose -f docker-compose-kafka.yml up -d

# Aguardar inicialização
Start-Sleep -Seconds 30

# Criar tópicos
foreach ($topic in @('user-events','order-events','payment-events','inventory-events','notification-events','audit-logs')) {
    docker exec kafka kafka-topics --create --topic $topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
}

Write-Host "✅ Kafka environment ready!"
```

## 🔍 Verificação do Ambiente

### Health Checks:
```bash
# Verificar se Kafka está rodando
curl -f http://localhost:8082/topics || echo "Kafka REST not available"

# Listar tópicos
kafka-topics.sh --list --bootstrap-server localhost:9092

# Testar produção/consumo
kafka-console-producer.sh --topic test --bootstrap-server localhost:9092
kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server localhost:9092
```

## 💰 Custos e Licenças

### Red Hat AMQ Streams:
- **Licença Red Hat** necessária
- **Suporte incluso**
- **~$2000-5000/ano** por instância

### Apache Kafka Open Source:
- **Gratuito**
- **Suporte comunidade**
- **Compatível 100%** com AMQ Streams

## ✅ Próximos Passos Recomendados

1. **Configurar Kafka Docker** para desenvolvimento
2. **Testar conexão** dos microserviços
3. **Validar tópicos** e mensagens
4. **Implementar monitoramento** básico
5. **Planejar migração** para AMQ Streams quando necessário

---
**Conclusão**: Para o projeto atual, recomendo iniciar com **Apache Kafka via Docker** que oferece compatibilidade total com Red Hat AMQ Streams, permitindo desenvolvimento e testes sem custos de licença.
