#!/bin/bash

# Script de Teste de Conectividade para AMQ Streams External
# Testa a conexão dos microserviços com o cluster Kafka externo

set -e

# Configurações
NAMESPACE="microservices"
KAFKA_HOST="${KAFKA_EXTERNAL_HOST:-your-redhat-kafka-host:9092}"
KAFKA_USERNAME="${KAFKA_USERNAME:-microservices-user}"
KAFKA_PASSWORD="${KAFKA_PASSWORD:-your-password}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Verificar se o cluster está rodando
check_cluster() {
    print_status "Verificando cluster Kubernetes..."
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cluster Kubernetes não está acessível"
        exit 1
    fi
    
    print_success "Cluster Kubernetes está acessível"
}

# Verificar se os pods estão rodando
check_pods() {
    print_status "Verificando status dos pods..."
    
    echo "Status dos pods no namespace $NAMESPACE:"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    # Verificar se todos os pods estão ready
    local not_ready=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    
    if [ "$not_ready" -gt 0 ]; then
        print_warning "Alguns pods não estão em estado Running"
        kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running
    else
        print_success "Todos os pods estão em estado Running"
    fi
}

# Testar conectividade de rede
test_network_connectivity() {
    print_status "Testando conectividade de rede com Kafka..."
    
    if [ "$KAFKA_HOST" == "your-redhat-kafka-host:9092" ]; then
        print_warning "Host Kafka não foi configurado. Use: export KAFKA_EXTERNAL_HOST=your-host:9092"
        return
    fi
    
    # Extrair host e porta
    IFS=':' read -ra HOST_PORT <<< "$KAFKA_HOST"
    local kafka_host="${HOST_PORT[0]}"
    local kafka_port="${HOST_PORT[1]}"
    
    # Teste de conectividade básica usando netcat
    print_status "Testando conectividade TCP para $kafka_host:$kafka_port..."
    
    # Criar pod temporário para teste
    kubectl run network-test --image=busybox --rm -it --restart=Never -- nc -z -v $kafka_host $kafka_port
    
    if [ $? -eq 0 ]; then
        print_success "Conectividade TCP com Kafka OK"
    else
        print_error "Falha na conectividade TCP com Kafka"
    fi
}

# Testar autenticação Kafka
test_kafka_auth() {
    print_status "Testando autenticação Kafka..."
    
    if [ "$KAFKA_USERNAME" == "microservices-user" ] || [ "$KAFKA_PASSWORD" == "your-password" ]; then
        print_warning "Credenciais padrão sendo usadas. Para teste real, configure KAFKA_USERNAME e KAFKA_PASSWORD"
        return
    fi
    
    # Criar configuração temporária do Kafka
    local temp_config="/tmp/kafka-test.properties"
    cat > $temp_config << EOF
bootstrap.servers=$KAFKA_HOST
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="$KAFKA_USERNAME" password="$KAFKA_PASSWORD";
ssl.truststore.location=/tmp/kafka.client.truststore.jks
ssl.truststore.password=changeit
EOF
    
    print_status "Configuração de teste criada em $temp_config"
    print_warning "Para teste completo, é necessário ter o kafka-console-producer instalado"
}

# Testar endpoints dos microserviços
test_microservices_endpoints() {
    print_status "Testando endpoints dos microserviços..."
    
    # Lista de serviços para testar
    local services=("log-producer-service:80" "log-consumer-service:80" "log-analytics-service:80")
    local ports=("8080" "8081" "8082")
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local port="${ports[$i]}"
        local service_name=$(echo $service | cut -d: -f1)
        
        print_status "Testando $service_name..."
        
        # Port-forward em background
        kubectl port-forward service/$service_name $port:80 -n $NAMESPACE &
        local pf_pid=$!
        
        # Aguardar um pouco para o port-forward estabelecer
        sleep 5
        
        # Testar health endpoint
        if curl -f -s http://localhost:$port/actuator/health > /dev/null; then
            print_success "$service_name está respondendo em localhost:$port"
            
            # Testar endpoint específico baseado no serviço
            case $service_name in
                "log-producer-service")
                    if curl -f -s http://localhost:$port/api/logs/health > /dev/null; then
                        print_success "Endpoint /api/logs/health está funcionando"
                    else
                        print_warning "Endpoint /api/logs/health não está disponível"
                    fi
                    ;;
                "log-consumer-service")
                    if curl -f -s http://localhost:$port/api/consumer/status > /dev/null; then
                        print_success "Endpoint /api/consumer/status está funcionando"
                    else
                        print_warning "Endpoint /api/consumer/status não está disponível"
                    fi
                    ;;
                "log-analytics-service")
                    if curl -f -s http://localhost:$port/api/analytics/health > /dev/null; then
                        print_success "Endpoint /api/analytics/health está funcionando"
                    else
                        print_warning "Endpoint /api/analytics/health não está disponível"
                    fi
                    ;;
            esac
        else
            print_error "$service_name não está respondendo em localhost:$port"
        fi
        
        # Matar o port-forward
        kill $pf_pid 2>/dev/null || true
        
        # Aguardar um pouco antes do próximo teste
        sleep 2
    done
}

# Testar banco de dados
test_database() {
    print_status "Testando conectividade com PostgreSQL..."
    
    # Port-forward para PostgreSQL
    kubectl port-forward service/postgres-service 5432:5432 -n $NAMESPACE &
    local pf_pid=$!
    
    sleep 5
    
    # Testar conexão com pg_isready se disponível
    if command -v pg_isready &> /dev/null; then
        if pg_isready -h localhost -p 5432; then
            print_success "PostgreSQL está acessível"
        else
            print_error "PostgreSQL não está acessível"
        fi
    else
        print_warning "pg_isready não está disponível. Instale postgresql-client para teste completo"
    fi
    
    # Matar port-forward
    kill $pf_pid 2>/dev/null || true
}

# Testar Redis
test_redis() {
    print_status "Testando conectividade com Redis..."
    
    # Port-forward para Redis
    kubectl port-forward service/redis-service 6379:6379 -n $NAMESPACE &
    local pf_pid=$!
    
    sleep 5
    
    # Testar conexão com redis-cli se disponível
    if command -v redis-cli &> /dev/null; then
        if redis-cli -h localhost -p 6379 ping | grep -q PONG; then
            print_success "Redis está acessível"
        else
            print_error "Redis não está acessível"
        fi
    else
        print_warning "redis-cli não está disponível. Instale redis-tools para teste completo"
    fi
    
    # Matar port-forward
    kill $pf_pid 2>/dev/null || true
}

# Verificar logs dos microserviços
check_logs() {
    print_status "Verificando logs dos microserviços..."
    
    local deployments=("log-producer-service" "log-consumer-service" "log-analytics-service")
    
    for deployment in "${deployments[@]}"; do
        print_status "Logs recentes de $deployment:"
        echo "----------------------------------------"
        kubectl logs deployment/$deployment -n $NAMESPACE --tail=10 | head -20
        echo ""
    done
}

# Teste de envio de log
test_log_sending() {
    print_status "Testando envio de log para o Producer..."
    
    # Port-forward para producer
    kubectl port-forward service/log-producer-service 8080:80 -n $NAMESPACE &
    local pf_pid=$!
    
    sleep 5
    
    # Criar payload de teste
    local test_payload='{
        "level": "INFO",
        "message": "Teste de conectividade híbrida",
        "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
        "service": "connectivity-test",
        "metadata": {
            "test": true,
            "environment": "hybrid-deployment"
        }
    }'
    
    print_status "Enviando log de teste..."
    
    if curl -X POST \
        -H "Content-Type: application/json" \
        -d "$test_payload" \
        -f -s http://localhost:8080/api/logs/send > /dev/null; then
        print_success "Log enviado com sucesso para o Producer"
    else
        print_error "Falha ao enviar log para o Producer"
    fi
    
    # Matar port-forward
    kill $pf_pid 2>/dev/null || true
}

# Relatório final
generate_report() {
    echo ""
    echo "==============================================="
    echo "📊 RELATÓRIO DE CONECTIVIDADE"
    echo "==============================================="
    echo "Namespace: $NAMESPACE"
    echo "Kafka Host: $KAFKA_HOST"
    echo "Kafka Username: $KAFKA_USERNAME"
    echo "Data/Hora: $(date)"
    echo ""
    echo "Status dos Recursos:"
    kubectl get all -n $NAMESPACE
    echo ""
    echo "ConfigMaps:"
    kubectl get configmaps -n $NAMESPACE
    echo ""
    echo "Secrets:"
    kubectl get secrets -n $NAMESPACE
}

# Função principal
main() {
    echo "==============================================="
    echo "🔍 Teste de Conectividade Híbrida"
    echo "==============================================="
    echo ""
    
    check_cluster
    check_pods
    test_network_connectivity
    test_kafka_auth
    test_microservices_endpoints
    test_database
    test_redis
    check_logs
    test_log_sending
    generate_report
    
    print_success "Teste de conectividade concluído! 🎉"
}

# Verificar argumentos
case "${1:-test}" in
    "test"|"connectivity")
        main
        ;;
    "pods")
        check_pods
        ;;
    "network")
        test_network_connectivity
        ;;
    "endpoints")
        test_microservices_endpoints
        ;;
    "logs")
        check_logs
        ;;
    *)
        echo "Uso: $0 [test|pods|network|endpoints|logs]"
        echo "  test      - Teste completo de conectividade (padrão)"
        echo "  pods      - Verificar status dos pods"
        echo "  network   - Testar conectividade de rede"
        echo "  endpoints - Testar endpoints dos microserviços"
        echo "  logs      - Verificar logs dos microserviços"
        exit 1
        ;;
esac
