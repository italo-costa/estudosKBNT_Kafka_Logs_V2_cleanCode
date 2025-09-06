#!/bin/bash
# Startup Script - WSL Docker Compose
# Gerado em: 2025-09-06 20:32:19

echo "🚀 INICIANDO AMBIENTE KBNT - WSL LINUX"
echo "======================================"

# Verificar Docker
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker não está disponível"
    exit 1
fi

if ! docker-compose --version > /dev/null 2>&1; then
    echo "❌ Docker Compose não está disponível"
    exit 1
fi

echo "✅ Docker e Docker Compose detectados"

# Ir para diretório do projeto
WORKSPACE_PATH="/mnt/c/workspace/estudosKBNT_Kafka_Logs"
cd "$WORKSPACE_PATH" || {
    echo "❌ Não foi possível acessar $WORKSPACE_PATH"
    exit 1
}

echo "📁 Diretório: $(pwd)"

# Iniciar serviços
echo "🚀 Iniciando Docker Compose..."
docker-compose -f 04-infrastructure-layer/docker/docker-compose.scalable.yml up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização (30s)..."
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Health checks
echo "🏥 Verificando saúde dos serviços..."
for port in 8080 8081 8082 8083 8084 8085; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/actuator/health | grep -q "200"; then
        echo "✅ Serviço na porta $port: Saudável"
    else
        echo "❌ Serviço na porta $port: Não responsivo"
    fi
done

echo ""
echo "🎉 AMBIENTE INICIADO!"
echo "🌐 API Gateway: http://localhost:8080"
echo "📊 Métricas: http://localhost:9080/actuator"
echo "📋 Para ver logs: docker-compose -f 04-infrastructure-layer/docker/docker-compose.scalable.yml logs"
