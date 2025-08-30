#!/bin/bash

# Deploy Kafka Topics Script
# This script deploys all Kafka topics independently of microservices

set -e

NAMESPACE="kafka"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TOPICS_DIR="$SCRIPT_DIR/../topics"

echo "🚀 Deploying Kafka Topics..."

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Namespace '$NAMESPACE' not found. Please deploy infrastructure first."
    exit 1
fi

# Check if Kafka cluster is ready
echo "🔍 Checking Kafka cluster readiness..."
if ! kubectl get kafka kafka-cluster -n $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Kafka cluster 'kafka-cluster' not found. Please deploy infrastructure first."
    exit 1
fi

# Wait for Kafka cluster to be ready
echo "⏳ Waiting for Kafka cluster to be ready..."
kubectl wait --for=condition=Ready kafka/kafka-cluster -n $NAMESPACE --timeout=300s

# Deploy topics in order
topics=("application-logs" "error-logs" "audit-logs" "financial-logs")

for topic in "${topics[@]}"; do
    echo "📝 Deploying topic: $topic"
    
    if [ -f "$TOPICS_DIR/$topic/topic-config.yaml" ]; then
        kubectl apply -f "$TOPICS_DIR/$topic/topic-config.yaml"
        
        # Wait for topic to be ready
        echo "⏳ Waiting for topic '$topic' to be ready..."
        kubectl wait --for=condition=Ready kafkatopic/$topic -n $NAMESPACE --timeout=60s
        
        echo "✅ Topic '$topic' deployed successfully"
    else
        echo "❌ Configuration file not found: $TOPICS_DIR/$topic/topic-config.yaml"
        exit 1
    fi
done

echo ""
echo "🎉 All Kafka topics deployed successfully!"
echo ""
echo "📊 Topic Status:"
kubectl get kafkatopic -n $NAMESPACE

echo ""
echo "🔍 To verify topic creation on Kafka cluster:"
echo "kubectl exec -it kafka-cluster-kafka-0 -n $NAMESPACE -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list"
