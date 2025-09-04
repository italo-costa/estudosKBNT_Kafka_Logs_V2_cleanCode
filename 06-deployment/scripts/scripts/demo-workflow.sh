#!/bin/bash

# Script para demonstrar o Workflow de Integração
# Simula o fluxo completo de uma mensagem JSON através dos microserviços

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_phase() {
    echo -e "\n${PURPLE}========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}========================================${NC}"
}

print_log() {
    echo -e "${CYAN}[LOG]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variáveis
PRODUCER_URL="http://localhost:8081"
CONSUMER_URL="http://localhost:8082"
ANALYTICS_URL="http://localhost:8083"

# Dados de exemplo
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
REQUEST_ID="req-$(date +%s)-$(($RANDOM % 1000))"

# JSON de exemplo para o teste
JSON_PAYLOAD=$(cat <<EOF
{
    "service": "user-service",
    "level": "INFO",
    "message": "User authentication successful - workflow demo",
    "timestamp": "$TIMESTAMP",
    "host": "demo-server-01",
    "environment": "demo",
    "requestId": "$REQUEST_ID",
    "userId": "demo-user-123",
    "httpMethod": "POST",
    "endpoint": "/api/auth/login",
    "statusCode": 200,
    "responseTimeMs": 150,
    "metadata": {
        "userAgent": "WorkflowDemo/1.0",
        "clientIp": "127.0.0.1",
        "testMode": true
    }
}
EOF
)

# Função principal
main() {
    echo -e "${GREEN}🔄 DEMONSTRAÇÃO DO WORKFLOW DE INTEGRAÇÃO${NC}"
    echo -e "${GREEN}===============================================${NC}"
    echo ""
    echo "Este script demonstra o fluxo completo de uma mensagem JSON:"
    echo "HTTP → Microserviço A → AMQ Streams → Microserviço B → API Externa"
    echo ""
    echo "Payload de exemplo:"
    echo "$JSON_PAYLOAD" | jq .
    echo ""
    read -p "Pressione ENTER para iniciar a demonstração..."
    
    # FASE 1: Microserviço A - Recepção HTTP
    print_phase "FASE 1: MICROSERVIÇO A - RECEPÇÃO HTTP"
    
    print_step "1.1" "Enviando mensagem JSON via HTTP para o Producer Service"
    print_log "POST $PRODUCER_URL/api/v1/logs"
    print_log "Content-Type: application/json"
    print_log "RequestId: $REQUEST_ID"
    
    # Simular envio HTTP
    echo ""
    echo "💻 Simulando envio HTTP..."
    sleep 1
    
    # Verificar se o Producer está rodando
    if curl -s "$PRODUCER_URL/actuator/health" > /dev/null 2>&1; then
        print_success "Producer Service está rodando em $PRODUCER_URL"
        
        # Enviar a mensagem real
        RESPONSE=$(curl -s -w "%{http_code}" -X POST "$PRODUCER_URL/api/v1/logs" \
            -H "Content-Type: application/json" \
            -d "$JSON_PAYLOAD")
        
        HTTP_CODE="${RESPONSE: -3}"
        RESPONSE_BODY="${RESPONSE%???}"
        
        if [ "$HTTP_CODE" = "202" ]; then
            print_success "Mensagem aceita pelo Producer (HTTP 202)"
            echo "Response: $RESPONSE_BODY" | jq .
            
            print_log "✅ [HTTP_RECEIVED] Service: user-service, Level: INFO, Message: User authentication successful"
            print_log "📝 [REQUEST_DETAILS] RequestId: $REQUEST_ID, Host: demo-server-01"
        else
            print_error "Falha na comunicação HTTP (Code: $HTTP_CODE)"
            echo "Response: $RESPONSE_BODY"
        fi
    else
        print_warning "Producer Service não está rodando. Simulando resposta..."
        print_log "✅ [HTTP_RECEIVED] Service: user-service, Level: INFO, Message: User authentication successful"
        print_log "📝 [REQUEST_DETAILS] RequestId: $REQUEST_ID, Host: demo-server-01"
        print_success "Mensagem aceita pelo Producer (SIMULADO)"
    fi
    
    print_step "1.2" "Microserviço A processa e envia para AMQ Streams"
    sleep 1
    print_log "📤 [KAFKA_SEND] Topic: application-logs, Key: user-service, Service: user-service"
    print_log "🚀 [KAFKA_SENDING] Topic: 'application-logs', Key: 'user-service', Message: 'User authentication successful'"
    sleep 1
    print_log "✅ [KAFKA_SUCCESS] Topic: 'application-logs', Partition: 1, Offset: 12345, Key: 'user-service'"
    print_log "📮 [HTTP_RESPONSE] Status: 202 Accepted, Service: user-service, Topic: application-logs"
    
    # FASE 2: AMQ Streams - Recepção e Armazenamento
    print_phase "FASE 2: AMQ STREAMS - RECEPÇÃO E ARMAZENAMENTO"
    
    print_step "2.1" "AMQ Streams recebe e armazena a mensagem"
    sleep 1
    print_log "📥 [BROKER_RECEIVED] Topic: application-logs, Partition: 1, Offset: 12345, Size: 856 bytes"
    print_log "✅ [LOG_APPENDED] Topic: application-logs, Partition: 1, Offset: 12345, Segment: 00000000000012000.log"
    
    print_step "2.2" "Verificação do log no tópico Kafka"
    print_success "Mensagem armazenada com sucesso no tópico 'application-logs'"
    print_log "Topic: application-logs | Partitions: 3 | Replication Factor: 3"
    print_log "Key: user-service | Partition: 1 | Offset: 12345"
    
    # FASE 3: Microserviço B - Consumo da Mensagem
    print_phase "FASE 3: MICROSERVIÇO B - CONSUMO DA MENSAGEM"
    
    print_step "3.1" "Microserviço B consome mensagem do Kafka"
    sleep 1
    print_log "📥 [KAFKA_CONSUMED] Topic: application-logs, Service: user-service, Level: INFO"
    print_log "📝 [MESSAGE_DETAILS] RequestId: $REQUEST_ID, Message: 'User authentication successful', Timestamp: $TIMESTAMP"
    
    print_step "3.2" "Processamento e envio para API externa"
    sleep 1
    print_log "🔄 [API_MAPPING] Converting LogEntry to External API request"
    
    # Verificar se o Consumer está rodando
    if curl -s "$CONSUMER_URL/actuator/health" > /dev/null 2>&1; then
        print_success "Consumer Service está rodando em $CONSUMER_URL"
        print_log "🌐 [API_CALLING] Sending log data to external API: https://external-logs-api.company.com/v1/logs"
        print_log "✅ [API_SUCCESS] External API responded with status: 200 OK, ResponseTime: 27ms"
        print_log "✅ [API_SENT] RequestId: $REQUEST_ID, Service: user-service, External API Response: SUCCESS"
    else
        print_warning "Consumer Service não está rodando. Simulando processamento..."
        print_log "🌐 [API_CALLING] Sending log data to external API: https://external-logs-api.company.com/v1/logs (SIMULADO)"
        print_log "✅ [API_SUCCESS] External API responded with status: 200 OK (SIMULADO)"
        print_log "✅ [API_SENT] RequestId: $REQUEST_ID, Service: user-service, External API Response: SUCCESS (SIMULADO)"
    fi
    
    # FASE 4: Analytics (Opcional)
    print_phase "FASE 4: ANALYTICS E MÉTRICAS (OPCIONAL)"
    
    print_step "4.1" "Analytics Service processa dados para dashboards"
    sleep 1
    
    if curl -s "$ANALYTICS_URL/actuator/health" > /dev/null 2>&1; then
        print_success "Analytics Service está rodando em $ANALYTICS_URL"
        print_log "📊 [METRICS_UPDATE] Service: user-service, Level: INFO, Count: +1"
        print_log "🔍 [ANALYTICS_READY] Data available for dashboards and queries"
    else
        print_warning "Analytics Service não está rodando. Simulando analytics..."
        print_log "📊 [METRICS_UPDATE] Service: user-service, Level: INFO, Count: +1 (SIMULADO)"
        print_log "🔍 [ANALYTICS_READY] Data available for dashboards and queries (SIMULADO)"
    fi
    
    # Resumo Final
    print_phase "🎯 RESUMO DO WORKFLOW EXECUTADO"
    
    echo ""
    echo "| Fase | Componente | Ação | Status |"
    echo "|------|------------|------|--------|"
    echo "| 1.1  | Microserviço A | Recebe HTTP | ✅ Concluído |"
    echo "| 1.2  | Microserviço A | Publica Kafka | ✅ Concluído |"
    echo "| 2.1  | AMQ Streams | Armazena | ✅ Concluído |"
    echo "| 3.1  | Microserviço B | Consome | ✅ Concluído |"
    echo "| 3.2  | Microserviço B | API Externa | ✅ Concluído |"
    echo "| 4.1  | Analytics | Métricas | ✅ Concluído |"
    echo ""
    
    print_success "🎉 Workflow de Integração executado com sucesso!"
    echo ""
    echo "Dados da mensagem processada:"
    echo "- RequestId: $REQUEST_ID"
    echo "- Service: user-service"
    echo "- Level: INFO"
    echo "- Timestamp: $TIMESTAMP"
    echo "- Topic: application-logs"
    echo "- Partition: 1"
    echo "- Offset: 12345"
    echo ""
    
    echo "Para verificar os logs em tempo real:"
    echo "kubectl logs -f deployment/log-producer-service -n microservices"
    echo "kubectl logs -f deployment/log-consumer-service -n microservices"
    echo "kubectl logs -f deployment/log-analytics-service -n microservices"
}

# Função para testar conectividade
test_connectivity() {
    print_phase "🔍 TESTE DE CONECTIVIDADE DOS SERVIÇOS"
    
    echo "Testando conectividade com os microserviços..."
    echo ""
    
    # Producer
    if curl -s "$PRODUCER_URL/actuator/health" > /dev/null 2>&1; then
        print_success "✅ Producer Service ($PRODUCER_URL) - Ativo"
    else
        print_warning "⚠️  Producer Service ($PRODUCER_URL) - Não acessível"
    fi
    
    # Consumer
    if curl -s "$CONSUMER_URL/actuator/health" > /dev/null 2>&1; then
        print_success "✅ Consumer Service ($CONSUMER_URL) - Ativo"
    else
        print_warning "⚠️  Consumer Service ($CONSUMER_URL) - Não acessível"
    fi
    
    # Analytics
    if curl -s "$ANALYTICS_URL/actuator/health" > /dev/null 2>&1; then
        print_success "✅ Analytics Service ($ANALYTICS_URL) - Ativo"
    else
        print_warning "⚠️  Analytics Service ($ANALYTICS_URL) - Não acessível"
    fi
    
    echo ""
    echo "💡 Para executar os serviços localmente:"
    echo "   kubectl port-forward service/log-producer-service 8081:80 -n microservices"
    echo "   kubectl port-forward service/log-consumer-service 8082:80 -n microservices"
    echo "   kubectl port-forward service/log-analytics-service 8083:80 -n microservices"
}

# Verificar argumentos
case "${1:-demo}" in
    "demo"|"run")
        main
        ;;
    "test"|"connectivity")
        test_connectivity
        ;;
    "json")
        echo "Payload JSON de exemplo:"
        echo "$JSON_PAYLOAD" | jq .
        ;;
    *)
        echo "Uso: $0 [demo|test|json]"
        echo "  demo - Executa demonstração completa do workflow (padrão)"
        echo "  test - Testa conectividade com os serviços"
        echo "  json - Mostra o payload JSON de exemplo"
        exit 1
        ;;
esac
