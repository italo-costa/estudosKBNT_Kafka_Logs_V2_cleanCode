#!/bin/bash

# Script de Deploy para Hybrid Deployment
# Microserviços em Kubernetes Local conectando ao AMQ Streams Externo

set -e

echo "==============================================="
echo "🚀 Deploy Híbrido - AMQ Streams + Microserviços"
echo "==============================================="

# Variáveis de configuração
NAMESPACE="microservices"
KAFKA_EXTERNAL_HOST="${KAFKA_EXTERNAL_HOST:-your-redhat-kafka-host:9092}"
KAFKA_USERNAME="${KAFKA_USERNAME:-microservices-user}"
KAFKA_PASSWORD="${KAFKA_PASSWORD:-your-password}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Verificar pré-requisitos
check_prerequisites() {
    print_status "Verificando pré-requisitos..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl não está instalado"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "docker não está instalado"
        exit 1
    fi
    
    # Verificar conexão com cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Não foi possível conectar ao cluster Kubernetes"
        exit 1
    fi
    
    print_success "Pré-requisitos verificados"
}

# Construir imagens Docker
build_docker_images() {
    print_status "Construindo imagens Docker..."
    
    # Producer Service
    if [ -d "../microservices/log-producer-service" ]; then
        print_status "Construindo log-producer-service..."
        cd ../microservices/log-producer-service
        docker build -t log-producer-service:latest .
        cd - > /dev/null
        print_success "log-producer-service construído"
    else
        print_warning "Diretório log-producer-service não encontrado"
    fi
    
    # Consumer Service
    if [ -d "../microservices/log-consumer-service" ]; then
        print_status "Construindo log-consumer-service..."
        cd ../microservices/log-consumer-service
        docker build -t log-consumer-service:latest .
        cd - > /dev/null
        print_success "log-consumer-service construído"
    else
        print_warning "Diretório log-consumer-service não encontrado"
    fi
    
    # Analytics Service
    if [ -d "../microservices/log-analytics-service" ]; then
        print_status "Construindo log-analytics-service..."
        cd ../microservices/log-analytics-service
        docker build -t log-analytics-service:latest .
        cd - > /dev/null
        print_success "log-analytics-service construído"
    else
        print_warning "Diretório log-analytics-service não encontrado"
    fi
}

# Configurar secrets e configmaps
configure_secrets() {
    print_status "Configurando secrets e configmaps..."
    
    # Atualizar ConfigMap com configurações reais
    if [ "$KAFKA_EXTERNAL_HOST" != "your-redhat-kafka-host:9092" ]; then
        kubectl patch configmap kafka-external-config -n $NAMESPACE --type merge -p "{\"data\":{\"bootstrap-servers\":\"$KAFKA_EXTERNAL_HOST\"}}"
        print_success "Bootstrap servers atualizados: $KAFKA_EXTERNAL_HOST"
    else
        print_warning "KAFKA_EXTERNAL_HOST não foi definido. Use: export KAFKA_EXTERNAL_HOST=your-host:9092"
    fi
    
    # Atualizar credenciais se fornecidas
    if [ "$KAFKA_USERNAME" != "microservices-user" ] || [ "$KAFKA_PASSWORD" != "your-password" ]; then
        kubectl patch secret kafka-external-credentials -n $NAMESPACE --type merge -p "{\"stringData\":{\"kafka-username\":\"$KAFKA_USERNAME\",\"kafka-password\":\"$KAFKA_PASSWORD\"}}"
        print_success "Credenciais Kafka atualizadas"
    else
        print_warning "Credenciais padrão sendo usadas. Defina: KAFKA_USERNAME e KAFKA_PASSWORD"
    fi
}

# Deploy da infraestrutura
deploy_infrastructure() {
    print_status "Fazendo deploy da infraestrutura..."
    
    # Aplicar manifestos de infraestrutura
    kubectl apply -f infrastructure.yaml
    
    print_status "Aguardando infraestrutura ficar pronta..."
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=120s
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=60s
    
    print_success "Infraestrutura deployada com sucesso"
}

# Deploy dos microserviços
deploy_microservices() {
    print_status "Fazendo deploy dos microserviços..."
    
    # Aplicar manifestos de microserviços
    kubectl apply -f microservices.yaml
    
    print_status "Aguardando microserviços ficarem prontos..."
    
    # Aguardar deployments
    kubectl wait --for=condition=available deployment/log-producer-service -n $NAMESPACE --timeout=180s
    kubectl wait --for=condition=available deployment/log-consumer-service -n $NAMESPACE --timeout=180s
    kubectl wait --for=condition=available deployment/log-analytics-service -n $NAMESPACE --timeout=180s
    
    print_success "Microserviços deployados com sucesso"
}

# Teste de conectividade
test_connectivity() {
    print_status "Testando conectividade..."
    
    # Testar conectividade com Kafka externo
    print_status "Testando conectividade com AMQ Streams..."
    
    # Port-forward para testar o producer
    kubectl port-forward service/log-producer-service 8080:80 -n $NAMESPACE &
    PF_PID=$!
    
    sleep 10
    
    # Teste básico do health endpoint
    if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
        print_success "Producer service está respondendo"
    else
        print_warning "Producer service não está respondendo na porta 8080"
    fi
    
    # Cleanup port-forward
    kill $PF_PID 2>/dev/null || true
    
    # Mostrar status dos pods
    print_status "Status dos pods:"
    kubectl get pods -n $NAMESPACE
    
    print_status "Status dos services:"
    kubectl get svc -n $NAMESPACE
}

# Mostrar informações de acesso
show_access_info() {
    echo ""
    echo "==============================================="
    echo "🎯 Informações de Acesso"
    echo "==============================================="
    
    echo "Para acessar os serviços localmente:"
    echo ""
    echo "📊 Producer Service (REST API):"
    echo "   kubectl port-forward service/log-producer-service 8080:80 -n $NAMESPACE"
    echo "   http://localhost:8080/actuator/health"
    echo "   http://localhost:8080/api/logs/send"
    echo ""
    echo "📊 Consumer Service:"
    echo "   kubectl port-forward service/log-consumer-service 8081:80 -n $NAMESPACE"
    echo "   http://localhost:8081/actuator/health"
    echo ""
    echo "📊 Analytics Service:"
    echo "   kubectl port-forward service/log-analytics-service 8082:80 -n $NAMESPACE"
    echo "   http://localhost:8082/actuator/health"
    echo ""
    echo "🔍 Monitoramento:"
    echo "   kubectl logs -f deployment/log-producer-service -n $NAMESPACE"
    echo "   kubectl logs -f deployment/log-consumer-service -n $NAMESPACE"
    echo ""
    echo "🗄️  Database (PostgreSQL):"
    echo "   kubectl port-forward service/postgres-service 5432:5432 -n $NAMESPACE"
    echo "   psql -h localhost -U loguser -d loganalytics"
    echo ""
    echo "🔴 Redis:"
    echo "   kubectl port-forward service/redis-service 6379:6379 -n $NAMESPACE"
    echo "   redis-cli -h localhost"
}

# Função principal
main() {
    echo "Iniciando deploy híbrido..."
    echo "Namespace: $NAMESPACE"
    echo "Kafka Host: $KAFKA_EXTERNAL_HOST"
    echo ""
    
    check_prerequisites
    
    # Criar namespace se não existir
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    build_docker_images
    deploy_infrastructure
    configure_secrets
    deploy_microservices
    test_connectivity
    show_access_info
    
    print_success "Deploy híbrido concluído com sucesso! 🎉"
}

# Função de cleanup
cleanup() {
    print_status "Limpando recursos..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    print_success "Recursos removidos"
}

# Verificar argumentos
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "cleanup")
        cleanup
        ;;
    "test")
        test_connectivity
        ;;
    *)
        echo "Uso: $0 [deploy|cleanup|test]"
        echo "  deploy  - Deploy completo (padrão)"
        echo "  cleanup - Remove todos os recursos"
        echo "  test    - Testa conectividade"
        exit 1
        ;;
esac
