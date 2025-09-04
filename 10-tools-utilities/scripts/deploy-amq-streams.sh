#!/bin/bash

# =============================================================================
# Red Hat AMQ Streams Deployment Script for KBNT Logging System
# =============================================================================

set -e

echo "🔴 Red Hat AMQ Streams - KBNT Logging System Deployment"
echo "========================================================"
echo "Date: $(date)"
echo "Environment: Production Ready"
echo "Kafka Version: 3.5.0"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="kafka"
CLUSTER_NAME="kbnt-kafka-cluster"
USER_NAME="kbnt-logging-user"

echo -e "${BLUE}📋 Pre-deployment checks...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if oc is available (OpenShift CLI)
if ! command -v oc &> /dev/null; then
    echo -e "${YELLOW}⚠️  OpenShift CLI (oc) not found, using kubectl only${NC}"
    USE_OC=false
else
    echo -e "${GREEN}✅ OpenShift CLI (oc) available${NC}"
    USE_OC=true
fi

# Check cluster connectivity
echo -e "${BLUE}🔍 Checking cluster connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    echo "Please ensure you are logged in to your OpenShift/Kubernetes cluster"
    exit 1
fi

echo -e "${GREEN}✅ Connected to cluster${NC}"

# Check if Strimzi operator is installed
echo -e "${BLUE}🔍 Checking Strimzi operator...${NC}"
if ! kubectl get crd kafkas.kafka.strimzi.io &> /dev/null; then
    echo -e "${YELLOW}⚠️  Strimzi operator not detected, installing...${NC}"
    
    # Install Strimzi operator
    echo -e "${BLUE}📦 Installing Strimzi operator...${NC}"
    kubectl create namespace strimzi-system 2>/dev/null || true
    kubectl apply -f 'https://strimzi.io/install/latest?namespace=strimzi-system' -n strimzi-system
    
    echo -e "${BLUE}⏳ Waiting for Strimzi operator to be ready...${NC}"
    kubectl wait --for=condition=Ready pod -l name=strimzi-cluster-operator -n strimzi-system --timeout=300s
    
    echo -e "${GREEN}✅ Strimzi operator installed successfully${NC}"
else
    echo -e "${GREEN}✅ Strimzi operator already installed${NC}"
fi

# Create or update namespace
echo -e "${BLUE}🏗️  Setting up namespace...${NC}"
kubectl create namespace ${NAMESPACE} 2>/dev/null || echo -e "${YELLOW}⚠️  Namespace ${NAMESPACE} already exists${NC}"
kubectl label namespace ${NAMESPACE} name=${NAMESPACE} --overwrite=true

# Deploy Kafka cluster
echo -e "${BLUE}🚀 Deploying Kafka cluster...${NC}"
echo "Cluster: ${CLUSTER_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Replicas: 3 brokers + 3 zookeepers"

kubectl apply -f kubernetes/amq-streams/kafka-cluster.yaml

# Wait for Kafka cluster to be ready
echo -e "${BLUE}⏳ Waiting for Kafka cluster to be ready (this may take several minutes)...${NC}"
echo "Checking cluster status every 30 seconds..."

TIMEOUT=1200  # 20 minutes timeout
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if kubectl get kafka ${CLUSTER_NAME} -n ${NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
        echo -e "${GREEN}✅ Kafka cluster is ready!${NC}"
        break
    fi
    
    echo -e "${YELLOW}⏳ Still waiting... (${ELAPSED}s/${TIMEOUT}s)${NC}"
    kubectl get kafka ${CLUSTER_NAME} -n ${NAMESPACE} -o jsonpath='{.status.conditions[*].type}:{.status.conditions[*].status}' || true
    sleep 30
    ELAPSED=$((ELAPSED + 30))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${RED}❌ Timeout waiting for Kafka cluster${NC}"
    echo "Checking cluster status:"
    kubectl describe kafka ${CLUSTER_NAME} -n ${NAMESPACE}
    exit 1
fi

# Verify Kafka pods are running
echo -e "${BLUE}🔍 Verifying Kafka pods...${NC}"
kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=kafka

echo ""
echo -e "${GREEN}🎉 Red Hat AMQ Streams deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "• Namespace: ${NAMESPACE}"
echo "• Cluster: ${CLUSTER_NAME}"
echo "• Kafka Version: 3.5.0"
echo "• Brokers: 3 replicas"
echo "• Zookeepers: 3 replicas"
echo "• Listeners: Plain (9092), TLS (9093), External (9094)"
echo ""

echo -e "${BLUE}🔗 Connection Information:${NC}"
echo "• Internal Plain: ${CLUSTER_NAME}-kafka-bootstrap.${NAMESPACE}.svc.cluster.local:9092"
echo "• Internal TLS: ${CLUSTER_NAME}-kafka-bootstrap.${NAMESPACE}.svc.cluster.local:9093"
echo ""

# Get external route if available
if $USE_OC; then
    echo -e "${BLUE}🌐 Getting external route...${NC}"
    EXTERNAL_ROUTE=$(oc get routes -n ${NAMESPACE} | grep ${CLUSTER_NAME}-kafka-bootstrap || echo "No external route found")
    echo "External Route: ${EXTERNAL_ROUTE}"
    echo ""
fi

echo -e "${BLUE}📋 Topics created:${NC}"
kubectl get kafkatopics -n ${NAMESPACE} -o custom-columns=NAME:.metadata.name,PARTITIONS:.spec.partitions,REPLICAS:.spec.replicas

echo ""
echo -e "${BLUE}👤 Users created:${NC}"
kubectl get kafkausers -n ${NAMESPACE} -o custom-columns=NAME:.metadata.name,AUTHENTICATION:.spec.authentication.type

echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Update microservice configurations with connection details"
echo "2. Deploy KBNT producer and consumer services"
echo "3. Run integration tests"
echo "4. Monitor cluster performance"
echo ""

echo -e "${BLUE}📊 Monitoring Commands:${NC}"
echo "• Check cluster status: kubectl get kafka ${CLUSTER_NAME} -n ${NAMESPACE}"
echo "• View broker logs: kubectl logs -f ${CLUSTER_NAME}-kafka-0 -n ${NAMESPACE}"
echo "• Check topics: kubectl get kafkatopics -n ${NAMESPACE}"
echo "• Monitor consumers: kubectl get kafkausers -n ${NAMESPACE}"
echo ""

echo -e "${GREEN}🏁 AMQ Streams is ready for KBNT microservices!${NC}"
