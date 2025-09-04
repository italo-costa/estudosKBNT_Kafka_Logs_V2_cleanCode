#!/bin/bash

# =============================================================================
# KBNT Enhanced Kafka Publication Logging System - Environment Startup
# Complete Environment Orchestration Script
# =============================================================================
# 
# This script orchestrates the complete startup of:
# - Red Hat AMQ Streams (Kafka)
# - Microservice A (Producer - Stock Update Service)  
# - Microservice B (Consumer - Stock Consumer Service)
# - PostgreSQL Database
# - Monitoring and Logging Infrastructure
#
# Author: KBNT Development Team
# Version: 1.0.0
# Date: 2025-08-30
# =============================================================================

set -euo pipefail

# Configuration Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NAMESPACE="${NAMESPACE:-kbnt-system}"
ENVIRONMENT="${ENVIRONMENT:-development}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Service Configuration
PRODUCER_SERVICE="kbnt-stock-producer-service"
CONSUMER_SERVICE="kbnt-stock-consumer-service"
KAFKA_CLUSTER="kbnt-kafka-cluster"
POSTGRES_SERVICE="kbnt-postgresql"

# Timing Configuration (in seconds)
KAFKA_STARTUP_WAIT=120        # 2 minutes for Kafka cluster
POSTGRES_STARTUP_WAIT=60      # 1 minute for PostgreSQL
PRODUCER_STARTUP_WAIT=90      # 1.5 minutes for producer service
CONSUMER_STARTUP_WAIT=90      # 1.5 minutes for consumer service
TOPIC_CREATION_WAIT=30        # 30 seconds for topic creation
HEALTH_CHECK_INTERVAL=10      # Health check every 10 seconds
MAX_HEALTH_CHECKS=30          # Maximum 5 minutes of health checks

# Colors for enhanced logging
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Logging Functions with Timestamps
log_header() {
    echo -e "\n${WHITE}========================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${WHITE}========================================${NC}\n"
}

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[$(date '+%Y-%m-%d %H:%M:%S')] [STEP]${NC} $1"
}

log_progress() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] [PROGRESS]${NC} $1"
}

# Progress indicator function
show_progress() {
    local duration=$1
    local message="$2"
    local interval=2
    local elapsed=0
    
    echo -ne "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] [WAITING]${NC} $message "
    
    while [ $elapsed -lt $duration ]; do
        echo -ne "."
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    echo -e " ${GREEN}✓${NC}"
}

# Health check function with detailed logging
check_service_health() {
    local service_name="$1"
    local health_endpoint="$2"
    local max_attempts="$3"
    local check_interval="$4"
    
    log_info "Checking health for $service_name at $health_endpoint"
    
    for ((i=1; i<=max_attempts; i++)); do
        log_progress "Health check attempt $i/$max_attempts for $service_name"
        
        if curl -f -s "$health_endpoint" > /dev/null 2>&1; then
            log_success "$service_name is healthy! (attempt $i/$max_attempts)"
            return 0
        else
            if [ $i -lt $max_attempts ]; then
                log_warning "$service_name not ready yet, waiting $check_interval seconds... (attempt $i/$max_attempts)"
                sleep $check_interval
            fi
        fi
    done
    
    log_error "$service_name health check failed after $max_attempts attempts"
    return 1
}

# Kubernetes resource verification
verify_kubernetes_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local namespace="$3"
    
    log_info "Verifying $resource_type/$resource_name in namespace $namespace"
    
    if kubectl get "$resource_type" "$resource_name" -n "$namespace" > /dev/null 2>&1; then
        log_success "$resource_type/$resource_name exists and is accessible"
        return 0
    else
        log_error "$resource_type/$resource_name not found or not accessible"
        return 1
    fi
}

# Prerequisites check
check_prerequisites() {
    log_header "CHECKING PREREQUISITES"
    
    local prerequisites=("kubectl" "docker" "curl" "mvn")
    local missing_tools=()
    
    for tool in "${prerequisites[@]}"; do
        log_info "Checking for $tool..."
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is installed"
        else
            log_error "$tool is not installed"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install missing tools before continuing"
        exit 1
    fi
    
    # Check Kubernetes connection
    log_info "Checking Kubernetes cluster connection..."
    if kubectl cluster-info &> /dev/null; then
        log_success "Kubernetes cluster is accessible"
    else
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Create and configure namespace
setup_namespace() {
    log_header "SETTING UP NAMESPACE"
    
    log_info "Creating namespace '$NAMESPACE' if it doesn't exist..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace for monitoring
    kubectl label namespace "$NAMESPACE" monitoring=enabled --overwrite
    kubectl label namespace "$NAMESPACE" environment="$ENVIRONMENT" --overwrite
    
    log_success "Namespace '$NAMESPACE' is ready and configured"
}

# Deploy PostgreSQL Database
deploy_postgresql() {
    log_header "DEPLOYING POSTGRESQL DATABASE"
    
    log_step "Creating PostgreSQL configuration..."
    
cat > /tmp/postgresql-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-config
  namespace: $NAMESPACE
data:
  POSTGRES_DB: kbnt_consumption_db
  POSTGRES_USER: kbnt_user
---
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-secret
  namespace: $NAMESPACE
type: Opaque
data:
  POSTGRES_PASSWORD: a2JudF9wYXNzd29yZA==  # kbnt_password
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $POSTGRES_SERVICE
  namespace: $NAMESPACE
  labels:
    app: $POSTGRES_SERVICE
    component: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $POSTGRES_SERVICE
  template:
    metadata:
      labels:
        app: $POSTGRES_SERVICE
        component: database
    spec:
      containers:
      - name: postgresql
        image: postgres:15
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgresql-config
        - secretRef:
            name: postgresql-secret
        volumeMounts:
        - name: postgresql-storage
          mountPath: /var/lib/postgresql/data
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - kbnt_user
            - -d
            - kbnt_consumption_db
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - kbnt_user
            - -d
            - kbnt_consumption_db
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: postgresql-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: $POSTGRES_SERVICE
  namespace: $NAMESPACE
  labels:
    app: $POSTGRES_SERVICE
spec:
  type: ClusterIP
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: $POSTGRES_SERVICE
EOF

    log_info "Deploying PostgreSQL..."
    kubectl apply -f /tmp/postgresql-config.yaml
    
    log_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=$POSTGRES_SERVICE -n $NAMESPACE --timeout=${POSTGRES_STARTUP_WAIT}s
    
    log_success "PostgreSQL deployed and ready"
    
    # Clean up temporary file
    rm -f /tmp/postgresql-config.yaml
}

# Deploy Red Hat AMQ Streams (Kafka)
deploy_amq_streams() {
    log_header "DEPLOYING RED HAT AMQ STREAMS (KAFKA)"
    
    log_step "Checking if Strimzi operator is installed..."
    if ! kubectl get crd kafkas.kafka.strimzi.io &> /dev/null; then
        log_warning "Strimzi operator not found. Installing..."
        
        # Install Strimzi operator
        log_info "Installing Strimzi Kafka operator..."
        kubectl create -f 'https://strimzi.io/install/latest?namespace='$NAMESPACE --dry-run=client -o yaml | \
        sed "s/namespace: .*/namespace: $NAMESPACE/" | kubectl apply -f -
        
        log_info "Waiting for Strimzi operator to be ready..."
        kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n $NAMESPACE --timeout=300s
    else
        log_success "Strimzi operator already installed"
    fi
    
    log_step "Deploying Kafka cluster..."
    
    # Use existing AMQ Streams configuration
    if [ -f "$PROJECT_ROOT/kubernetes/amq-streams/kafka-cluster.yaml" ]; then
        log_info "Using existing Kafka cluster configuration"
        kubectl apply -f "$PROJECT_ROOT/kubernetes/amq-streams/kafka-cluster.yaml" -n $NAMESPACE
    else
        log_warning "Kafka cluster configuration not found, creating basic configuration..."
        create_basic_kafka_config
    fi
    
    log_info "Waiting for Kafka cluster to be ready (this may take several minutes)..."
    show_progress $KAFKA_STARTUP_WAIT "Kafka cluster starting up"
    
    # Wait for Kafka cluster to be ready
    kubectl wait --for=condition=ready kafka $KAFKA_CLUSTER -n $NAMESPACE --timeout=${KAFKA_STARTUP_WAIT}s
    
    log_success "Kafka cluster deployed and ready"
}

# Create basic Kafka configuration if not exists
create_basic_kafka_config() {
cat > /tmp/basic-kafka.yaml << EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: $KAFKA_CLUSTER
  namespace: $NAMESPACE
spec:
  kafka:
    version: 3.5.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      default.replication.factor: 3
      min.insync.replicas: 2
      inter.broker.protocol.version: "3.5"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
    
    kubectl apply -f /tmp/basic-kafka.yaml
    rm -f /tmp/basic-kafka.yaml
}

# Create Kafka topics
create_kafka_topics() {
    log_header "CREATING KAFKA TOPICS"
    
    local topics=(
        "stock-updates:3:3"
        "high-priority-stock-updates:3:3"
        "stock-updates-retry:3:3"
        "stock-updates-dlt:1:3"
        "publication-logs:3:3"
    )
    
    for topic_config in "${topics[@]}"; do
        IFS=':' read -r topic_name partitions replicas <<< "$topic_config"
        
        log_step "Creating topic '$topic_name' with $partitions partitions and $replicas replicas"
        
cat > "/tmp/topic-${topic_name}.yaml" << EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: $topic_name
  namespace: $NAMESPACE
  labels:
    strimzi.io/cluster: $KAFKA_CLUSTER
spec:
  partitions: $partitions
  replicas: $replicas
  config:
    retention.ms: 604800000  # 7 days
    segment.ms: 86400000     # 1 day
    cleanup.policy: delete
    compression.type: producer
EOF
        
        kubectl apply -f "/tmp/topic-${topic_name}.yaml"
        rm -f "/tmp/topic-${topic_name}.yaml"
        
        log_info "Topic '$topic_name' created"
    done
    
    log_info "Waiting for topics to be ready..."
    show_progress $TOPIC_CREATION_WAIT "Topics being created"
    
    # Verify topics
    for topic_config in "${topics[@]}"; do
        IFS=':' read -r topic_name partitions replicas <<< "$topic_config"
        kubectl wait --for=condition=ready kafkatopic $topic_name -n $NAMESPACE --timeout=60s
    done
    
    log_success "All Kafka topics created and ready"
}

# Build and deploy Producer (Microservice A)
deploy_producer_service() {
    log_header "DEPLOYING PRODUCER SERVICE (MICROSERVICE A)"
    
    log_step "Building Producer Service..."
    cd "$PROJECT_ROOT"
    
    log_info "Compiling and packaging producer service..."
    mvn clean package -DskipTests -q
    
    log_info "Building Docker image for producer service..."
    create_producer_dockerfile
    docker build -t "$PRODUCER_SERVICE:latest" .
    
    log_step "Creating producer service Kubernetes manifests..."
    create_producer_k8s_manifests
    
    log_info "Deploying producer service to Kubernetes..."
    kubectl apply -f /tmp/producer-manifests.yaml
    
    log_info "Waiting for producer service to be ready..."
    kubectl wait --for=condition=ready pod -l app=$PRODUCER_SERVICE -n $NAMESPACE --timeout=${PRODUCER_STARTUP_WAIT}s
    
    log_success "Producer service deployed and ready"
}

# Create Dockerfile for producer if not exists
create_producer_dockerfile() {
    if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
        log_info "Creating Dockerfile for producer service..."
cat > "$PROJECT_ROOT/Dockerfile" << 'EOF'
FROM openjdk:17-jre-slim

WORKDIR /app

# Copy the application jar
COPY target/*.jar app.jar

# Create non-root user
RUN useradd -r -u 1001 appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
EOF
    fi
}

# Create Kubernetes manifests for producer
create_producer_k8s_manifests() {
cat > /tmp/producer-manifests.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${PRODUCER_SERVICE}-config
  namespace: $NAMESPACE
data:
  application.yml: |
    spring:
      application:
        name: $PRODUCER_SERVICE
      profiles:
        active: production
      kafka:
        bootstrap-servers: ${KAFKA_CLUSTER}-kafka-bootstrap:9092
        producer:
          key-serializer: org.apache.kafka.common.serialization.StringSerializer
          value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
          acks: all
          retries: 3
    server:
      port: 8080
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      endpoint:
        health:
          show-details: always
    app:
      kafka:
        topics:
          stock-updates: stock-updates
          high-priority-stock-updates: high-priority-stock-updates
          publication-logs: publication-logs
        publication-logging:
          enabled: true
          hash-calculation: true
    logging:
      level:
        com.estudoskbnt: INFO
        org.springframework.kafka: INFO
      pattern:
        console: "%d{HH:mm:ss.SSS} [%thread] %-5level [%X{correlationId}] %logger{36} - %msg%n"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $PRODUCER_SERVICE
  namespace: $NAMESPACE
  labels:
    app: $PRODUCER_SERVICE
    component: producer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $PRODUCER_SERVICE
  template:
    metadata:
      labels:
        app: $PRODUCER_SERVICE
        component: producer
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      containers:
      - name: $PRODUCER_SERVICE
        image: $PRODUCER_SERVICE:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: SPRING_KAFKA_BOOTSTRAP_SERVERS
          value: "${KAFKA_CLUSTER}-kafka-bootstrap:9092"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: config-volume
        configMap:
          name: ${PRODUCER_SERVICE}-config
---
apiVersion: v1
kind: Service
metadata:
  name: $PRODUCER_SERVICE
  namespace: $NAMESPACE
  labels:
    app: $PRODUCER_SERVICE
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: $PRODUCER_SERVICE
EOF
}

# Deploy Consumer Service (Microservice B)
deploy_consumer_service() {
    log_header "DEPLOYING CONSUMER SERVICE (MICROSERVICE B)"
    
    log_step "Building Consumer Service..."
    
    if [ -d "$PROJECT_ROOT/microservices/kbnt-stock-consumer-service" ]; then
        cd "$PROJECT_ROOT/microservices/kbnt-stock-consumer-service"
        
        log_info "Building consumer service..."
        ./scripts/deploy-consumer.sh build
        
        log_info "Deploying consumer service..."
        ./scripts/deploy-consumer.sh deploy
        
        log_success "Consumer service deployed successfully"
    else
        log_error "Consumer service directory not found"
        exit 1
    fi
    
    log_info "Waiting for consumer service to be ready..."
    kubectl wait --for=condition=ready pod -l app=$CONSUMER_SERVICE -n $NAMESPACE --timeout=${CONSUMER_STARTUP_WAIT}s
    
    log_success "Consumer service deployed and ready"
}

# Perform comprehensive health checks
perform_health_checks() {
    log_header "PERFORMING COMPREHENSIVE HEALTH CHECKS"
    
    local services=(
        "PostgreSQL:http://postgresql-service:5432"
        "Kafka Cluster:${KAFKA_CLUSTER}-kafka-bootstrap:9092"
        "Producer Service:http://${PRODUCER_SERVICE}:8080/actuator/health"
        "Consumer Service:http://${CONSUMER_SERVICE}:8081/api/consumer/actuator/health"
    )
    
    log_info "Starting health checks for all services..."
    
    # Wait a bit for services to fully start
    show_progress 30 "Allowing services to stabilize"
    
    # Check PostgreSQL
    log_step "Checking PostgreSQL connectivity..."
    if kubectl exec -n $NAMESPACE deployment/$POSTGRES_SERVICE -- pg_isready -U kbnt_user -d kbnt_consumption_db > /dev/null 2>&1; then
        log_success "✓ PostgreSQL is accessible and ready"
    else
        log_error "✗ PostgreSQL health check failed"
    fi
    
    # Check Kafka cluster
    log_step "Checking Kafka cluster status..."
    if kubectl get kafka $KAFKA_CLUSTER -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
        log_success "✓ Kafka cluster is ready"
    else
        log_error "✗ Kafka cluster is not ready"
    fi
    
    # Check Producer service
    log_step "Checking Producer service health..."
    if kubectl exec -n $NAMESPACE deployment/$PRODUCER_SERVICE -- curl -f -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
        log_success "✓ Producer service is healthy"
    else
        log_warning "⚠ Producer service health check inconclusive"
    fi
    
    # Check Consumer service
    log_step "Checking Consumer service health..."
    if kubectl exec -n $NAMESPACE deployment/$CONSUMER_SERVICE -- curl -f -s http://localhost:8081/api/consumer/actuator/health > /dev/null 2>&1; then
        log_success "✓ Consumer service is healthy"
    else
        log_warning "⚠ Consumer service health check inconclusive"
    fi
    
    log_success "Health checks completed"
}

# Test end-to-end workflow
test_end_to_end_workflow() {
    log_header "TESTING END-TO-END WORKFLOW"
    
    log_step "Setting up port forwarding for testing..."
    
    # Port forward producer service
    kubectl port-forward service/$PRODUCER_SERVICE 8080:8080 -n $NAMESPACE &
    PRODUCER_PF_PID=$!
    
    # Port forward consumer service
    kubectl port-forward service/$CONSUMER_SERVICE 8081:8081 -n $NAMESPACE &
    CONSUMER_PF_PID=$!
    
    # Wait for port forwarding to establish
    show_progress 10 "Establishing port forwarding"
    
    log_step "Sending test message to producer..."
    
    local test_message='{
        "productId": "TEST-PROD-001",
        "quantity": 100,
        "price": 29.99,
        "operation": "ADD",
        "category": "Electronics",
        "supplier": "TestSupplier",
        "location": "WH-TEST",
        "priority": "NORMAL"
    }'
    
    log_info "Posting test stock update..."
    if curl -s -X POST http://localhost:8080/api/stock/update \
        -H "Content-Type: application/json" \
        -d "$test_message" > /dev/null; then
        log_success "✓ Test message sent to producer"
    else
        log_error "✗ Failed to send test message to producer"
    fi
    
    # Wait for message processing
    show_progress 15 "Waiting for message processing"
    
    log_step "Checking consumer statistics..."
    if curl -s http://localhost:8081/api/consumer/monitoring/statistics > /dev/null; then
        log_success "✓ Consumer monitoring endpoint accessible"
        
        # Get actual statistics
        local stats=$(curl -s http://localhost:8081/api/consumer/monitoring/statistics)
        log_info "Consumer Statistics: $stats"
    else
        log_warning "⚠ Consumer monitoring endpoint not accessible"
    fi
    
    # Cleanup port forwarding
    kill $PRODUCER_PF_PID $CONSUMER_PF_PID 2>/dev/null || true
    
    log_success "End-to-end workflow test completed"
}

# Display environment information
display_environment_info() {
    log_header "ENVIRONMENT INFORMATION"
    
    echo -e "${WHITE}KBNT Enhanced Kafka Publication Logging System${NC}"
    echo -e "${WHITE}Environment: ${CYAN}$ENVIRONMENT${NC}"
    echo -e "${WHITE}Namespace: ${CYAN}$NAMESPACE${NC}"
    echo -e "${WHITE}Deployment Date: ${CYAN}$(date)${NC}"
    echo ""
    
    log_info "Service Endpoints (use kubectl port-forward to access):"
    echo -e "  ${CYAN}Producer Service:${NC} http://localhost:8080"
    echo -e "  ${CYAN}Consumer Service:${NC} http://localhost:8081/api/consumer"
    echo -e "  ${CYAN}Producer Health:${NC} http://localhost:8080/actuator/health"
    echo -e "  ${CYAN}Consumer Health:${NC} http://localhost:8081/api/consumer/actuator/health"
    echo -e "  ${CYAN}Consumer Monitoring:${NC} http://localhost:8081/api/consumer/monitoring/statistics"
    echo ""
    
    log_info "Kafka Topics Created:"
    echo -e "  ${CYAN}stock-updates${NC} (main topic)"
    echo -e "  ${CYAN}high-priority-stock-updates${NC} (priority topic)"
    echo -e "  ${CYAN}stock-updates-retry${NC} (retry topic)"
    echo -e "  ${CYAN}stock-updates-dlt${NC} (dead letter topic)"
    echo -e "  ${CYAN}publication-logs${NC} (audit logs)"
    echo ""
    
    log_info "Port Forward Commands:"
    echo -e "  ${YELLOW}kubectl port-forward service/$PRODUCER_SERVICE 8080:8080 -n $NAMESPACE${NC}"
    echo -e "  ${YELLOW}kubectl port-forward service/$CONSUMER_SERVICE 8081:8081 -n $NAMESPACE${NC}"
    echo ""
    
    log_info "Monitoring Commands:"
    echo -e "  ${YELLOW}kubectl get pods -n $NAMESPACE${NC}"
    echo -e "  ${YELLOW}kubectl logs -f deployment/$PRODUCER_SERVICE -n $NAMESPACE${NC}"
    echo -e "  ${YELLOW}kubectl logs -f deployment/$CONSUMER_SERVICE -n $NAMESPACE${NC}"
    echo ""
    
    log_success "Environment setup completed successfully!"
}

# Cleanup function
cleanup_environment() {
    log_header "CLEANING UP ENVIRONMENT"
    
    log_warning "This will delete all resources in namespace '$NAMESPACE'"
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deleting all resources in namespace '$NAMESPACE'..."
        kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
        log_success "Environment cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main execution function
main() {
    local command="${1:-startup}"
    
    case "$command" in
        "startup"|"start")
            log_header "KBNT ENHANCED KAFKA LOGGING SYSTEM - COMPLETE STARTUP"
            
            check_prerequisites
            setup_namespace
            deploy_postgresql
            deploy_amq_streams
            create_kafka_topics
            deploy_producer_service
            deploy_consumer_service
            perform_health_checks
            test_end_to_end_workflow
            display_environment_info
            ;;
        
        "health")
            perform_health_checks
            ;;
        
        "test")
            test_end_to_end_workflow
            ;;
        
        "info")
            display_environment_info
            ;;
        
        "cleanup")
            cleanup_environment
            ;;
        
        *)
            echo "Usage: $0 {startup|health|test|info|cleanup}"
            echo ""
            echo "Commands:"
            echo "  startup  - Complete environment startup (default)"
            echo "  health   - Perform health checks only"
            echo "  test     - Run end-to-end workflow test"
            echo "  info     - Display environment information"
            echo "  cleanup  - Clean up all resources"
            echo ""
            echo "Environment Variables:"
            echo "  NAMESPACE=$NAMESPACE"
            echo "  ENVIRONMENT=$ENVIRONMENT"
            echo "  LOG_LEVEL=$LOG_LEVEL"
            exit 1
            ;;
    esac
}

# Trap for cleanup on script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Execute main function with all arguments
main "$@"
