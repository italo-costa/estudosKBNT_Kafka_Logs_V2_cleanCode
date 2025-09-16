# 🔌 MAPEAMENTO DE PORTAS - KBNT Kafka Logs System
# Arquivo de configuração centralizada para evitar conflitos de portas

## 📊 MAPA DE PORTAS PADRONIZADO

### 🏛️ INFRAESTRUTURA BASE (Portas 5000-6999)
POSTGRES_PRIMARY_PORT=5432
POSTGRES_REPLICA_PORT=5433  
REDIS_PRIMARY_PORT=6379
REDIS_REPLICA_PORT=6380

### 🔄 MESSAGE BROKERS (Portas 9000-9999)
ZOOKEEPER_PORT=2181
ZOOKEEPER_REPLICA_1=2182
ZOOKEEPER_REPLICA_2=2183
KAFKA_INTERNAL_PORT=9092
KAFKA_EXTERNAL_PORT=29092
KAFKA_JMX_PORT=9101
KAFKA_SCHEMA_REGISTRY_PORT=8081
KAFKA_CONNECT_PORT=8083
KAFKA_UI_PORT=8080

### 🚀 MICROSERVICOS API (Portas 8000-8999)
API_GATEWAY_PORT=8080
API_GATEWAY_MANAGEMENT_PORT=9080

VIRTUAL_STOCK_SERVICE_PORT=8084
VIRTUAL_STOCK_MANAGEMENT_PORT=9084

PRODUCER_SERVICE_PORT=8085
PRODUCER_MANAGEMENT_PORT=9085

CONSUMER_SERVICE_PORT=8086
CONSUMER_MANAGEMENT_PORT=9086

AUDIT_SERVICE_PORT=8087
AUDIT_MANAGEMENT_PORT=9087

NOTIFICATION_SERVICE_PORT=8088
NOTIFICATION_MANAGEMENT_PORT=9088

### 📊 MONITORAMENTO (Portas 9200-9999)
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_TRANSPORT_PORT=9300
KIBANA_PORT=5601
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
JAEGER_PORT=16686

### 🔧 PORTAS ALTERNATIVAS (Para ambientes com conflitos)
# PostgreSQL alternativo
POSTGRES_ALT_PORT=15432

# Kafka alternativo  
KAFKA_ALT_PORT=19092
ZOOKEEPER_ALT_PORT=12181

# Microserviços alternativos
VIRTUAL_STOCK_ALT_PORT=18084
API_GATEWAY_ALT_PORT=18080

## 🎯 CONFIGURAÇÕES POR AMBIENTE

### 🏠 DESENVOLVIMENTO (docker-compose.yml)
# Usar portas padrão para facilidade de desenvolvimento
# PostgreSQL: 5432
# Virtual Stock: 8084  
# API Gateway: 8080
# Kafka: 9092

### 🧪 TESTE/CI (docker-compose.free-tier.yml)
# Usar portas alternativas para evitar conflitos em CI
# PostgreSQL: 15432
# Virtual Stock: 18084
# API Gateway: 18080
# Kafka: 19092

### 🏭 PRODUÇÃO (docker-compose.scalable.yml)
# Load balancer nas portas padrão, serviços em portas internas
# Load Balancer: 80, 443
# Serviços internos: 8080+
# Kafka cluster: 9092-9094

## ⚠️ CONFLITOS IDENTIFICADOS E SOLUÇÕES

### 🔥 CONFLITOS ENCONTRADOS:
1. **Kafka UI (8080) vs API Gateway (8080)**
   - Solução: Kafka UI → 8090

2. **Schema Registry (8081) vs Consumer Service (8081)**  
   - Solução: Schema Registry → 8091

3. **PostgreSQL (5432) - múltiplas instâncias**
   - Solução: Primary=5432, Replica=5433

4. **Virtual Stock Service - portas inconsistentes**
   - Alguns arquivos: 8084
   - Outros arquivos: 8080 
   - Solução: Padronizar para 8084

### ✅ PLANO DE CORREÇÃO:
1. Atualizar todos os docker-compose para usar portas consistentes
2. Corrigir application.yml dos microserviços
3. Atualizar scripts PowerShell/Bash
4. Atualizar documentação Postman
5. Criar validação de conflitos de portas

## 📋 CHECKLIST DE VALIDAÇÃO
- [ ] Nenhuma porta duplicada no mesmo docker-compose
- [ ] Portas de aplicação consistentes entre arquivos
- [ ] Scripts atualizados com novas portas
- [ ] Documentação Postman atualizada
- [ ] Health checks usando portas corretas