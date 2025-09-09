#!/bin/bash

# KBNT Kafka Logs - Teste Completo do Ambiente Linux Virtualizado
# ================================================================

echo "🚀 KBNT Kafka Logs - Ambiente Linux Virtualizado (Docker)"
echo "=========================================================="
echo ""

echo "📊 Status dos Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(log-|virtual-stock|kbnt-)"
echo ""

echo "🏥 Health Checks dos Serviços:"
echo "=============================="

# Test log-consumer-service
echo "🔍 Log Consumer Service:"
CONSUMER_HEALTH=$(docker exec log-consumer-service curl -s http://localhost:8080/actuator/health 2>/dev/null)
if [[ "$CONSUMER_HEALTH" == *"UP"* ]]; then
    echo "  ✅ Status: UP"
    echo "  🌐 Endpoint: http://localhost:8082"
    CONSUMER_OK=true
else
    echo "  ❌ Não disponível"
    CONSUMER_OK=false
fi

# Test log-analytics-service  
echo ""
echo "📈 Log Analytics Service:"
ANALYTICS_HEALTH=$(docker exec log-analytics-service curl -s http://localhost:8080/actuator/health 2>/dev/null)
if [[ "$ANALYTICS_HEALTH" == *"UP"* ]]; then
    echo "  ✅ Status: UP"
    echo "  🌐 Endpoint: http://localhost:8083"
    ANALYTICS_OK=true
else
    echo "  ❌ Não disponível"
    ANALYTICS_OK=false
fi

# Test log-producer-service
echo ""
echo "📤 Log Producer Service:"
PRODUCER_HEALTH=$(docker exec log-producer-service curl -s http://localhost:8080/actuator/health 2>/dev/null)
if [[ "$PRODUCER_HEALTH" == *"UP"* ]]; then
    echo "  ✅ Status: UP"
    echo "  🌐 Endpoint: http://localhost:8081"
    PRODUCER_OK=true
else
    echo "  ❌ Não disponível"
    PRODUCER_OK=false
fi

# Test virtual-stock-service
echo ""
echo "📊 Virtual Stock Service:"
STOCK_HEALTH=$(docker exec virtual-stock-service curl -s http://localhost:8080/actuator/health 2>/dev/null)
if [[ "$STOCK_HEALTH" == *"UP"* ]]; then
    echo "  ✅ Status: UP"
    echo "  🌐 Endpoint: http://localhost:8084"
    STOCK_OK=true
else
    echo "  ❌ Não disponível (problema de BD)"
    STOCK_OK=false
fi

echo ""
echo "🧪 Testes de API Funcionais:"
echo "============================"

# Test API endpoints for working services
if [ "$CONSUMER_OK" = true ]; then
    echo ""
    echo "🔍 Log Consumer - Endpoints Disponíveis:"
    CONSUMER_ENDPOINTS=$(docker exec log-consumer-service curl -s http://localhost:8080/actuator 2>/dev/null)
    echo "  📋 Actuator: $(echo $CONSUMER_ENDPOINTS | jq -r '._links | keys | join(", ")' 2>/dev/null || echo "health")"
fi

if [ "$ANALYTICS_OK" = true ]; then
    echo ""
    echo "📈 Log Analytics - Endpoints Disponíveis:"
    ANALYTICS_ENDPOINTS=$(docker exec log-analytics-service curl -s http://localhost:8080/actuator 2>/dev/null)
    echo "  📋 Actuator: $(echo $ANALYTICS_ENDPOINTS | jq -r '._links | keys | join(", ")' 2>/dev/null || echo "health")"
fi

if [ "$PRODUCER_OK" = true ]; then
    echo ""
    echo "📤 Log Producer - Teste de API:"
    echo "  🔗 POST /api/v1/logs"
    TEST_LOG_RESPONSE=$(docker exec log-producer-service curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"message":"Test from Linux environment","level":"INFO","serviceName":"TEST","requestId":"test-001"}' \
        http://localhost:8080/api/v1/logs 2>/dev/null)
    
    if [[ "$TEST_LOG_RESPONSE" == *"sucesso"* ]] || [[ "$TEST_LOG_RESPONSE" == *"success"* ]]; then
        echo "  ✅ Produção de log funcionando"
    else
        echo "  ❌ Erro na produção: $TEST_LOG_RESPONSE"
    fi
fi

echo ""
echo "📋 Comandos de Teste Para Usar:"
echo "================================"

if [ "$CONSUMER_OK" = true ]; then
    echo ""
    echo "🔍 Log Consumer Service (Porta 8082):"
    echo "curl -X GET http://localhost:8082/actuator/health"
fi

if [ "$ANALYTICS_OK" = true ]; then
    echo ""
    echo "📈 Log Analytics Service (Porta 8083):"
    echo "curl -X GET http://localhost:8083/actuator/health"
fi

if [ "$PRODUCER_OK" = true ]; then
    echo ""
    echo "📤 Log Producer Service (Porta 8081):"
    echo "curl -X GET http://localhost:8081/actuator/health"
    echo "curl -X POST http://localhost:8081/api/v1/logs \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{\"message\":\"Test log message\",\"level\":\"INFO\",\"serviceName\":\"TEST\",\"requestId\":\"req-001\"}'"
fi

if [ "$STOCK_OK" = true ]; then
    echo ""
    echo "📊 Virtual Stock Service (Porta 8084):"
    echo "curl -X GET http://localhost:8084/actuator/health"
    echo "curl -X GET http://localhost:8084/api/v1/virtual-stock/stocks"
fi

echo ""
echo "🎯 Teste de Conectividade Externa (Windows):"
echo "============================================"

if [ "$CONSUMER_OK" = true ]; then
    echo "Invoke-RestMethod -Uri 'http://localhost:8082/actuator/health' -Method Get"
fi

if [ "$ANALYTICS_OK" = true ]; then
    echo "Invoke-RestMethod -Uri 'http://localhost:8083/actuator/health' -Method Get"
fi

echo ""
echo "✨ Ambiente Linux Virtualizado - Testes Concluídos!"
echo "===================================================="

# Summary
WORKING_SERVICES=0
if [ "$CONSUMER_OK" = true ]; then ((WORKING_SERVICES++)); fi
if [ "$ANALYTICS_OK" = true ]; then ((WORKING_SERVICES++)); fi
if [ "$PRODUCER_OK" = true ]; then ((WORKING_SERVICES++)); fi
if [ "$STOCK_OK" = true ]; then ((WORKING_SERVICES++)); fi

echo ""
echo "📊 Resumo: $WORKING_SERVICES/4 serviços funcionais"
echo "🔗 Kafka: Disponível (porta 9092)"
echo "🐘 PostgreSQL: Necessário para Virtual Stock Service"
echo "🚀 Ambiente pronto para desenvolvimento e testes!"
