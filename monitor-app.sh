#!/bin/bash

# Monitor Virtual Stock Service - Monitoramento contínuo da aplicação
# Executa verificações a cada 30 segundos e reinicia containers se necessário

echo "=== Monitor Virtual Stock Service ==="
echo "Iniciando monitoramento contínuo..."
echo "Pressione Ctrl+C para parar"
echo

check_container() {
    local container_name=$1
    local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
    
    if [ "$status" != "running" ]; then
        echo "[$(date)] ⚠️  Container $container_name não está rodando. Status: $status"
        echo "[$(date)] 🔄 Reiniciando $container_name..."
        docker start "$container_name"
        sleep 5
    else
        echo "[$(date)] ✅ Container $container_name está funcionando"
    fi
}

check_health() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8084/actuator/health 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "[$(date)] ✅ API está respondendo (HTTP $response)"
        return 0
    else
        echo "[$(date)] ❌ API não está respondendo (HTTP $response)"
        return 1
    fi
}

# Loop principal
while true; do
    echo "[$(date)] === Verificação de Saúde ==="
    
    # Verificar containers
    check_container "postgres-kbnt-stable"
    check_container "virtual-stock-stable"
    
    # Verificar saúde da API
    if ! check_health; then
        echo "[$(date)] 🔄 Tentando reiniciar aplicação..."
        docker restart virtual-stock-stable
        sleep 30
    fi
    
    echo "[$(date)] 💤 Aguardando próxima verificação..."
    echo
    sleep 30
done
