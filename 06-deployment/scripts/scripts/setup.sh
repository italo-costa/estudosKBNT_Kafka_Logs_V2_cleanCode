#!/bin/bash

# Script de setup completo para o ambiente de estudos Kafka + Kubernetes

set -e

echo "🚀 Configurando ambiente de estudos Kafka + Kubernetes"
echo "================================================="

# Função para verificar se um comando existe
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 não está instalado. Por favor, instale $1 antes de continuar."
        exit 1
    else
        echo "✅ $1 está instalado"
    fi
}

# Verificar dependências
echo "🔍 Verificando dependências..."
check_command docker
check_command kubectl
check_command helm
check_command python3

# Verificar se o Docker está rodando
if ! docker info &> /dev/null; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker."
    exit 1
fi
echo "✅ Docker está rodando"

# Instalar dependências Python
echo "📦 Instalando dependências Python..."
pip3 install -r requirements.txt

# Verificar/Criar namespace Kafka
echo "🏗️  Configurando namespace Kafka no Kubernetes..."
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -

# Deploy do Zookeeper
echo "🐘 Fazendo deploy do Zookeeper..."
kubectl apply -f kubernetes/zookeeper/zookeeper-deployment.yaml

# Aguardar Zookeeper estar pronto
echo "⏳ Aguardando Zookeeper estar pronto..."
kubectl wait --for=condition=ready pod -l app=zookeeper -n kafka --timeout=300s

# Deploy do Kafka
echo "📨 Fazendo deploy do Kafka..."
kubectl apply -f kubernetes/kafka/kafka-deployment.yaml

# Aguardar Kafka estar pronto
echo "⏳ Aguardando Kafka estar pronto..."
kubectl wait --for=condition=ready pod -l app=kafka -n kafka --timeout=300s

# Criar tópicos básicos
echo "📋 Criando tópicos básicos..."
kubectl exec -n kafka kafka-0 -- kafka-topics --create --topic application-logs --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists
kubectl exec -n kafka kafka-0 -- kafka-topics --create --topic error-logs --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists
kubectl exec -n kafka kafka-0 -- kafka-topics --create --topic metrics --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists

# Port-forward para acesso local
echo "🌐 Configurando port-forward para Kafka..."
kubectl port-forward -n kafka svc/kafka 9092:9092 &
KAFKA_PID=$!

echo ""
echo "✅ Setup concluído com sucesso!"
echo "================================================="
echo "🎯 O que você pode fazer agora:"
echo ""
echo "1. Testar o produtor de logs:"
echo "   python3 producers/python/log-producer.py --count 10"
echo ""
echo "2. Testar o consumidor de logs (em outro terminal):"
echo "   python3 consumers/python/log-consumer.py"
echo ""
echo "3. Ver tópicos criados:"
echo "   kubectl exec -n kafka kafka-0 -- kafka-topics --list --bootstrap-server localhost:9092"
echo ""
echo "4. Monitorar pods:"
echo "   kubectl get pods -n kafka"
echo ""
echo "5. Para parar o port-forward:"
echo "   kill $KAFKA_PID"
echo ""
echo "📚 Consulte a documentação em docs/ para mais exemplos!"
echo "================================================="
