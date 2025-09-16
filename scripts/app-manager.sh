#!/bin/bash

# =============================================================================
# Script de Inicialização Completa da Aplicação KBNT
# Mantém todos os serviços funcionando com restart automático
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
WORKSPACE_PATH="/mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode"
CHECK_INTERVAL=30
MAX_RETRIES=3

echo -e "${GREEN}🚀 INICIANDO APLICAÇÃO KBNT - CONFIGURAÇÃO COMPLETA${NC}"
echo -e "${CYAN}📍 Workspace: $WORKSPACE_PATH${NC}"
echo -e "${CYAN}⏰ Monitoramento a cada $CHECK_INTERVAL segundos${NC}"
echo "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "="

# Função para log com timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Função para verificar se container está rodando
check_container() {
    local container_name=$1
    docker ps --filter "name=$container_name" --format "{{.Status}}" | grep -q "Up"
}

# Função para aguardar serviço ficar saudável
wait_for_health() {
    local service_name=$1
    local health_url=$2
    local max_wait=${3:-60}
    local waited=0
    
    log "${YELLOW}⏳ Aguardando $service_name ficar saudável...${NC}"
    
    while [ $waited -lt $max_wait ]; do
        if curl -sf "$health_url" >/dev/null 2>&1; then
            log "${GREEN}✅ $service_name está saudável!${NC}"
            return 0
        fi
        
        sleep 5
        waited=$((waited + 5))
        echo -n "."
    done
    
    log "${RED}❌ $service_name não ficou saudável em ${max_wait}s${NC}"
    return 1
}

# Função para mostrar logs em caso de erro
show_error_logs() {
    local container_name=$1
    log "${YELLOW}📄 Últimos logs de $container_name:${NC}"
    docker logs "$container_name" --tail 10 2>&1 | sed 's/^/  /'
}

# Função para iniciar PostgreSQL
start_postgres() {
    log "${BLUE}🗄️ Iniciando PostgreSQL...${NC}"
    
    # Parar e remover se existir
    docker stop postgres-db 2>/dev/null || true
    docker rm postgres-db 2>/dev/null || true
    
    # Iniciar PostgreSQL
    docker run -d \
        --name postgres-db \
        --restart=always \
        -p 5432:5432 \
        -e POSTGRES_DB=kbnt_db \
        -e POSTGRES_USER=kbnt_user \
        -e POSTGRES_PASSWORD=kbnt_password \
        postgres:15
    
    # Aguardar PostgreSQL estar pronto
    sleep 15
    
    if check_container "postgres-db"; then
        log "${GREEN}✅ PostgreSQL iniciado com sucesso${NC}"
        return 0
    else
        log "${RED}❌ Falha ao iniciar PostgreSQL${NC}"
        show_error_logs "postgres-db"
        return 1
    fi
}

# Função para construir imagens se necessário
build_images() {
    log "${BLUE}🔨 Verificando e construindo imagens...${NC}"
    
    cd "$WORKSPACE_PATH/microservices"
    
    # Virtual Stock Service
    if ! docker images | grep -q "estudoskbnt_kafka_logs_v2_cleancode_virtual-stock-service-1"; then
        log "${YELLOW}🔨 Construindo Virtual Stock Service...${NC}"
        docker build -f virtual-stock-service/Dockerfile -t estudoskbnt_kafka_logs_v2_cleancode_virtual-stock-service-1 virtual-stock-service/
    fi
    
    # API Gateway
    if ! docker images | grep -q "estudoskbnt_kafka_logs_v2_cleancode_api-gateway-1"; then
        log "${YELLOW}🔨 Construindo API Gateway...${NC}"
        docker build -f api-gateway/Dockerfile -t estudoskbnt_kafka_logs_v2_cleancode_api-gateway-1 api-gateway/
    fi
    
    log "${GREEN}✅ Imagens prontas${NC}"
}

# Função para iniciar Virtual Stock Service
start_virtual_stock() {
    log "${BLUE}📦 Iniciando Virtual Stock Service...${NC}"
    
    # Parar e remover se existir
    docker stop virtual-stock-svc 2>/dev/null || true
    docker rm virtual-stock-svc 2>/dev/null || true
    
    # Iniciar Virtual Stock Service
    docker run -d \
        --name virtual-stock-svc \
        --restart=always \
        -p 0.0.0.0:8084:8080 \
        --add-host=host.docker.internal:host-gateway \
        -e SERVER_PORT=8080 \
        -e SPRING_DATASOURCE_URL='jdbc:postgresql://host.docker.internal:5432/kbnt_db' \
        -e SPRING_DATASOURCE_USERNAME=kbnt_user \
        -e SPRING_DATASOURCE_PASSWORD=kbnt_password \
        -e SPRING_PROFILES_ACTIVE=docker \
        estudoskbnt_kafka_logs_v2_cleancode_virtual-stock-service-1
    
    # Aguardar e verificar saúde
    sleep 20
    
    if wait_for_health "Virtual Stock Service" "http://172.30.221.62:8084/actuator/health" 60; then
        return 0
    else
        show_error_logs "virtual-stock-svc"
        return 1
    fi
}

# Função para iniciar API Gateway
start_api_gateway() {
    log "${BLUE}🌐 Iniciando API Gateway...${NC}"
    
    # Parar e remover se existir
    docker stop api-gateway-svc 2>/dev/null || true
    docker rm api-gateway-svc 2>/dev/null || true
    
    # Iniciar API Gateway
    docker run -d \
        --name api-gateway-svc \
        --restart=always \
        -p 0.0.0.0:8080:8080 \
        --add-host=host.docker.internal:host-gateway \
        -e SERVER_PORT=8080 \
        -e SPRING_PROFILES_ACTIVE=simple \
        estudoskbnt_kafka_logs_v2_cleancode_api-gateway-1
    
    # Aguardar e verificar saúde
    sleep 20
    
    if wait_for_health "API Gateway" "http://172.30.221.62:8080/actuator/health" 60; then
        return 0
    else
        show_error_logs "api-gateway-svc"
        return 1
    fi
}

# Função para verificar todos os serviços
check_all_services() {
    local all_healthy=true
    
    # PostgreSQL
    if check_container "postgres-db"; then
        log "${GREEN}✅ PostgreSQL: Rodando${NC}"
    else
        log "${RED}❌ PostgreSQL: Parado${NC}"
        all_healthy=false
    fi
    
    # Virtual Stock Service
    if check_container "virtual-stock-svc"; then
        if curl -sf "http://172.30.221.62:8084/actuator/health" >/dev/null 2>&1; then
            log "${GREEN}✅ Virtual Stock Service: Saudável${NC}"
        else
            log "${YELLOW}⚠️ Virtual Stock Service: Rodando mas sem health${NC}"
            all_healthy=false
        fi
    else
        log "${RED}❌ Virtual Stock Service: Parado${NC}"
        all_healthy=false
    fi
    
    # API Gateway
    if check_container "api-gateway-svc"; then
        if curl -sf "http://172.30.221.62:8080/actuator/health" >/dev/null 2>&1; then
            log "${GREEN}✅ API Gateway: Saudável${NC}"
        else
            log "${YELLOW}⚠️ API Gateway: Rodando mas sem health${NC}"
            all_healthy=false
        fi
    else
        log "${RED}❌ API Gateway: Parado${NC}"
        all_healthy=false
    fi
    
    if $all_healthy; then
        log "${GREEN}🎉 TODOS OS SERVIÇOS ESTÃO FUNCIONANDO!${NC}"
    else
        log "${YELLOW}⚠️ Alguns serviços precisam de atenção${NC}"
    fi
    
    return $all_healthy
}

# Função de restart automático
auto_restart_failed_services() {
    log "${YELLOW}🔄 Verificando serviços que precisam de restart...${NC}"
    
    # PostgreSQL
    if ! check_container "postgres-db"; then
        log "${YELLOW}🔄 Restartando PostgreSQL...${NC}"
        start_postgres
    fi
    
    # Virtual Stock Service
    if ! check_container "virtual-stock-svc" || ! curl -sf "http://172.30.221.62:8084/actuator/health" >/dev/null 2>&1; then
        log "${YELLOW}🔄 Restartando Virtual Stock Service...${NC}"
        start_virtual_stock
    fi
    
    # API Gateway
    if ! check_container "api-gateway-svc" || ! curl -sf "http://172.30.221.62:8080/actuator/health" >/dev/null 2>&1; then
        log "${YELLOW}🔄 Restartando API Gateway...${NC}"
        start_api_gateway
    fi
}

# Função principal de inicialização
main() {
    case "${1:-start}" in
        "start")
            log "${GREEN}🚀 INICIANDO TODOS OS SERVIÇOS...${NC}"
            
            # Limpar containers antigos
            log "${BLUE}🧹 Limpando containers antigos...${NC}"
            docker container prune -f >/dev/null 2>&1 || true
            
            # Construir imagens
            build_images
            
            # Iniciar serviços em ordem
            start_postgres && \
            start_virtual_stock && \
            start_api_gateway
            
            if [ $? -eq 0 ]; then
                log "${GREEN}🎉 APLICAÇÃO INICIADA COM SUCESSO!${NC}"
                log "${CYAN}📍 URLs Disponíveis:${NC}"
                log "${CYAN}  - Virtual Stock API: http://172.30.221.62:8084/api/v1/virtual-stock/stocks${NC}"
                log "${CYAN}  - API Gateway: http://172.30.221.62:8080/actuator/health${NC}"
                log "${CYAN}  - PostgreSQL: 172.30.221.62:5432${NC}"
            else
                log "${RED}❌ FALHA NA INICIALIZAÇÃO${NC}"
                exit 1
            fi
            ;;
            
        "status")
            check_all_services
            ;;
            
        "monitor")
            log "${GREEN}👁️ INICIANDO MONITORAMENTO CONTÍNUO...${NC}"
            while true; do
                if ! check_all_services; then
                    auto_restart_failed_services
                fi
                
                log "${CYAN}⏳ Próxima verificação em ${CHECK_INTERVAL}s...${NC}"
                sleep $CHECK_INTERVAL
            done
            ;;
            
        "stop")
            log "${YELLOW}🛑 PARANDO TODOS OS SERVIÇOS...${NC}"
            docker stop api-gateway-svc virtual-stock-svc postgres-db 2>/dev/null || true
            docker rm api-gateway-svc virtual-stock-svc postgres-db 2>/dev/null || true
            log "${GREEN}✅ Todos os serviços parados${NC}"
            ;;
            
        "restart")
            log "${YELLOW}🔄 REINICIANDO TODOS OS SERVIÇOS...${NC}"
            $0 stop
            sleep 5
            $0 start
            ;;
            
        *)
            echo "Uso: $0 {start|status|monitor|stop|restart}"
            echo ""
            echo "  start   - Iniciar todos os serviços"
            echo "  status  - Verificar status dos serviços"  
            echo "  monitor - Monitoramento contínuo com restart automático"
            echo "  stop    - Parar todos os serviços"
            echo "  restart - Reiniciar todos os serviços"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
