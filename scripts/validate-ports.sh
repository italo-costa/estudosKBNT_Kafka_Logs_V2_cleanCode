#!/bin/bash
# ============================================================================
# SCRIPT DE VALIDAÇÃO DE PORTAS - KBNT System  
# Verifica conflitos de portas em todos os docker-compose
# ============================================================================

echo "🔍 VALIDAÇÃO DE PORTAS - KBNT Kafka Logs System"
echo "=================================================="

WORKSPACE_ROOT="/mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode"
cd "$WORKSPACE_ROOT"

echo ""
echo "📊 Coletando portas de todos os docker-compose..."

# Coletar todas as portas dos docker-compose
TEMP_FILE="/tmp/port_analysis.txt"
> "$TEMP_FILE"

# Buscar por padrões de porta em docker-compose files
find . -name "docker-compose*.yml" -exec grep -H "\"[0-9]*:[0-9]*\"" {} \; >> "$TEMP_FILE"

echo "✅ Análise coletada. Verificando conflitos..."
echo ""

# Analisar conflitos específicos
echo "🔥 CONFLITOS IDENTIFICADOS:"
echo "================================"

# Verificar conflito PostgreSQL
POSTGRES_PORTS=$(grep -r "\"54[0-9][0-9]:543[0-9]\"" . --include="docker-compose*.yml" | wc -l)
if [ $POSTGRES_PORTS -gt 3 ]; then
    echo "❌ PostgreSQL: $POSTGRES_PORTS configurações encontradas (pode ter conflitos)"
else
    echo "✅ PostgreSQL: $POSTGRES_PORTS configurações (OK)"
fi

# Verificar conflito Virtual Stock Service
STOCK_8084=$(grep -r "\"8084:" . --include="docker-compose*.yml" | wc -l)
STOCK_8080=$(grep -r ":8080\"" . --include="docker-compose*.yml" | grep -v "8080:8080" | wc -l)
echo "📦 Virtual Stock Service:"
echo "   - Porta 8084: $STOCK_8084 ocorrências"
echo "   - Mapeando para :8080: $STOCK_8080 ocorrências"

# Verificar conflito API Gateway vs Kafka UI
API_GATEWAY_8080=$(grep -r "\"8080:8080\"" . --include="docker-compose*.yml" | wc -l)
echo "🌐 API Gateway (8080): $API_GATEWAY_8080 ocorrências"

# Verificar Kafka
KAFKA_9092=$(grep -r "\"9092:9092\"" . --include="docker-compose*.yml" | wc -l)
echo "🔄 Kafka (9092): $KAFKA_9092 ocorrências"

echo ""
echo "📋 RECOMENDAÇÕES DE CORREÇÃO:"
echo "================================"

if [ $STOCK_8080 -gt 0 ]; then
    echo "❌ Virtual Stock Service tem inconsistências de porta"
    echo "   → Padronizar todas para 8084:8084"
fi

if [ $API_GATEWAY_8080 -gt 1 ]; then
    echo "⚠️  Múltiplas instâncias na porta 8080"
    echo "   → Considerar portas alternativas para ambientes de teste"
fi

echo ""
echo "🎯 ARQUIVOS DOCKER-COMPOSE ANALISADOS:"
echo "======================================"
find . -name "docker-compose*.yml" -type f | sort

echo ""
echo "📊 RESUMO DE PORTAS POR TIPO:"
echo "============================"
echo "Database (PostgreSQL): 5432, 5433"
echo "Message Broker (Kafka): 9092, 29092"  
echo "Coordination (Zookeeper): 2181, 2182, 2183"
echo "API Gateway: 8080"
echo "Virtual Stock Service: 8084"
echo "Microservices: 8081-8088"
echo "Management Ports: 9080-9088"
echo "Monitoring (ES): 9200"

echo ""
echo "✅ Validação concluída!"
echo "💡 Execute './fix-port-conflicts.sh' para aplicar correções automáticas"