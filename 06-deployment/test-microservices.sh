#!/bin/bash

echo "🚀 KBNT Kafka Logs - Teste de Conectividade"
echo "==========================================="
echo ""

echo "📊 Verificando status dos containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(log-|virtual-stock|kbnt-)"

echo ""
echo "🏥 Testando Health Checks dos Microserviços:"
echo ""

# Test log-consumer-service
echo "🔍 Log Consumer Service (porta 8082):"
if docker exec log-consumer-service curl -s -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "  ✅ Health: $(docker exec log-consumer-service curl -s http://localhost:8080/actuator/health)"
else
    echo "  ❌ Serviço não respondeu"
fi

echo ""

# Test log-analytics-service  
echo "📈 Log Analytics Service (porta 8083):"
if docker exec log-analytics-service curl -s -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "  ✅ Health: $(docker exec log-analytics-service curl -s http://localhost:8080/actuator/health)"
else
    echo "  ❌ Serviço não respondeu"
fi

echo ""

# Test log-producer-service
echo "📤 Log Producer Service (porta 8081):"
if docker exec log-producer-service curl -s -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "  ✅ Health: $(docker exec log-producer-service curl -s http://localhost:8080/actuator/health)"
else
    echo "  ❌ Serviço não respondeu"
fi

echo ""

# Test virtual-stock-service
echo "📊 Virtual Stock Service (porta 8084):"
if docker exec virtual-stock-service curl -s -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "  ✅ Health: $(docker exec virtual-stock-service curl -s http://localhost:8080/actuator/health)"
else
    echo "  ❌ Serviço não respondeu"
fi

echo ""
echo "🔗 Testando conectividade entre serviços..."
echo ""

# Test network connectivity
echo "🌐 Testando conectividade de rede:"
if docker exec log-consumer-service ping -c 1 log-analytics-service > /dev/null 2>&1; then
    echo "  ✅ log-consumer-service → log-analytics-service"
else
    echo "  ❌ Falha na conectividade entre serviços"
fi

echo ""
echo "📋 Endpoints disponíveis para teste externo:"
echo "  🔹 http://localhost:8082/actuator/health (Log Consumer)"
echo "  🔹 http://localhost:8083/actuator/health (Log Analytics)" 
echo "  🔹 http://localhost:8081/actuator/health (Log Producer)"
echo "  🔹 http://localhost:8084/actuator/health (Virtual Stock)"
echo ""

echo "✨ Teste concluído!"
