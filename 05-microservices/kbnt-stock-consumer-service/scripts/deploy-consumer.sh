#!/bin/bash

# KBNT Stock Consumer Service Deployment Script
# Microservice B - Consumer for Red Hat AMQ Streams Integration
#
# This script deploys the consumer microservice to Kubernetes/OpenShift
# and configures it to consume from Red Hat AMQ Streams topics.

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_NAME="kbnt-stock-consumer-service"
NAMESPACE="${NAMESPACE:-kbnt-system}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-registry.redhat.io/estudoskbnt}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is required but not installed."
        exit 1
    fi
    
    # Check if Maven is installed
    if ! command -v mvn &> /dev/null; then
        log_error "Maven is required but not installed."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed."
        exit 1
    fi
    
    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi
    
    log_success "All prerequisites are met."
}

# Function to create namespace if it doesn't exist
create_namespace() {
    log_info "Creating namespace '$NAMESPACE' if it doesn't exist..."
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Namespace '$NAMESPACE' is ready."
}

# Function to build the application
build_application() {
    log_info "Building the application..."
    
    cd "$PROJECT_ROOT"
    
    # Clean and build
    mvn clean compile -DskipTests
    if [ $? -ne 0 ]; then
        log_error "Application build failed."
        exit 1
    fi
    
    # Run tests
    log_info "Running unit tests..."
    mvn test
    if [ $? -ne 0 ]; then
        log_warning "Some tests failed. Continuing with deployment..."
    fi
    
    # Package the application
    mvn package -DskipTests
    if [ $? -ne 0 ]; then
        log_error "Application packaging failed."
        exit 1
    fi
    
    log_success "Application built successfully."
}

# Function to build Docker image
build_docker_image() {
    log_info "Building Docker image..."
    
    cd "$PROJECT_ROOT"
    
    # Create Dockerfile if it doesn't exist
    if [ ! -f Dockerfile ]; then
        create_dockerfile
    fi
    
    # Build Docker image
    docker build -t "${REGISTRY}/${APP_NAME}:${IMAGE_TAG}" .
    if [ $? -ne 0 ]; then
        log_error "Docker image build failed."
        exit 1
    fi
    
    log_success "Docker image built: ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}"
}

# Function to create Dockerfile
create_dockerfile() {
    log_info "Creating Dockerfile..."
    
cat > Dockerfile << 'EOF'
FROM registry.redhat.io/ubi8/openjdk-17:latest

# Set working directory
WORKDIR /opt/app

# Copy the application jar
COPY target/*.jar app.jar

# Create non-root user
USER 1001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8081/api/consumer/actuator/health || exit 1

# Expose port
EXPOSE 8081

# Environment variables
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENV SERVER_PORT=8081

# Run the application
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
EOF

    log_success "Dockerfile created."
}

# Function to push Docker image
push_docker_image() {
    log_info "Pushing Docker image to registry..."
    
    # Login to registry if credentials are provided
    if [ -n "${REGISTRY_USERNAME:-}" ] && [ -n "${REGISTRY_PASSWORD:-}" ]; then
        echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY" -u "$REGISTRY_USERNAME" --password-stdin
    fi
    
    docker push "${REGISTRY}/${APP_NAME}:${IMAGE_TAG}"
    if [ $? -ne 0 ]; then
        log_warning "Failed to push Docker image. Continuing with local deployment..."
    else
        log_success "Docker image pushed successfully."
    fi
}

# Function to create Kubernetes manifests
create_kubernetes_manifests() {
    log_info "Creating Kubernetes manifests..."
    
    mkdir -p "$PROJECT_ROOT/k8s"
    
    # Create ConfigMap for application configuration
    create_configmap_manifest
    
    # Create Secret for sensitive configuration
    create_secret_manifest
    
    # Create Deployment manifest
    create_deployment_manifest
    
    # Create Service manifest
    create_service_manifest
    
    # Create ServiceMonitor for Prometheus monitoring
    create_servicemonitor_manifest
    
    log_success "Kubernetes manifests created."
}

# Function to create ConfigMap manifest
create_configmap_manifest() {
cat > "$PROJECT_ROOT/k8s/configmap.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APP_NAME}-config
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    component: consumer
    version: ${IMAGE_TAG}
data:
  application.yml: |
    spring:
      application:
        name: ${APP_NAME}
      profiles:
        active: production
      
      datasource:
        url: jdbc:postgresql://postgresql-service:5432/kbnt_consumption_db
        driver-class-name: org.postgresql.Driver
        username: \${DB_USERNAME}
        password: \${DB_PASSWORD}
      
      jpa:
        hibernate:
          ddl-auto: validate
        show-sql: false
        properties:
          hibernate:
            dialect: org.hibernate.dialect.PostgreSQLDialect

    server:
      port: 8081
      servlet:
        context-path: /api/consumer

    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      endpoint:
        health:
          show-details: always
      metrics:
        export:
          prometheus:
            enabled: true

    app:
      environment: production
      
      kafka:
        bootstrap-servers: \${KAFKA_BOOTSTRAP_SERVERS}
        consumer:
          group-id: \${KAFKA_CONSUMER_GROUP_ID}
          concurrency: 5
          max-poll-records: 500
        
        topics:
          stock-updates: stock-updates
          high-priority-stock-updates: high-priority-stock-updates
        
        security:
          protocol: \${KAFKA_SECURITY_PROTOCOL:SASL_SSL}
          ssl:
            trust-store-location: /opt/kafka/ssl/truststore.jks
            trust-store-password: \${KAFKA_SSL_TRUSTSTORE_PASSWORD}
          sasl:
            mechanism: \${KAFKA_SASL_MECHANISM:PLAIN}
            jaas-config: \${KAFKA_SASL_JAAS_CONFIG}
      
      external-api:
        stock-service:
          base-url: \${STOCK_SERVICE_URL}
          timeout: 10
          max-retries: 3

    logging:
      level:
        com.estudoskbnt.consumer: INFO
        org.springframework.kafka: INFO
      pattern:
        console: "%d{HH:mm:ss.SSS} [%thread] %-5level [%X{correlationId}] %logger{36} - %msg%n"
EOF
}

# Function to create Secret manifest
create_secret_manifest() {
cat > "$PROJECT_ROOT/k8s/secret.yaml" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${APP_NAME}-secret
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
type: Opaque
data:
  # Base64 encoded values - replace with actual values
  DB_USERNAME: a2JudF91c2Vy  # kbnt_user
  DB_PASSWORD: a2JudF9wYXNzd29yZA==  # kbnt_password
  KAFKA_SSL_TRUSTSTORE_PASSWORD: dHJ1c3RzdG9yZS1wYXNzd29yZA==  # truststore-password
  KAFKA_SASL_JAAS_CONFIG: b3JnLmFwYWNoZS5rYWZrYS5jb21tb24uc2VjdXJpdHkucGxhaW4uUGxhaW5Mb2dpbk1vZHVsZSByZXF1aXJlZCB1c2VybmFtZT0iY29uc3VtZXItdXNlciIgcGFzc3dvcmQ9ImNvbnN1bWVyLXBhc3N3b3JkIjs=
EOF
}

# Function to create Deployment manifest
create_deployment_manifest() {
cat > "$PROJECT_ROOT/k8s/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    component: consumer
    version: ${IMAGE_TAG}
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
        component: consumer
        version: ${IMAGE_TAG}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8081"
        prometheus.io/path: "/api/consumer/actuator/prometheus"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: ${APP_NAME}
        image: ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}
        imagePullPolicy: Always
        ports:
        - containerPort: 8081
          name: http
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: KAFKA_BOOTSTRAP_SERVERS
          value: "amq-streams-kafka-bootstrap:9092"
        - name: KAFKA_CONSUMER_GROUP_ID
          value: "kbnt-stock-consumer-group"
        - name: KAFKA_SECURITY_PROTOCOL
          value: "SASL_SSL"
        - name: KAFKA_SASL_MECHANISM
          value: "PLAIN"
        - name: STOCK_SERVICE_URL
          value: "http://kbnt-stock-producer-service:8080"
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: ${APP_NAME}-secret
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${APP_NAME}-secret
              key: DB_PASSWORD
        - name: KAFKA_SSL_TRUSTSTORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${APP_NAME}-secret
              key: KAFKA_SSL_TRUSTSTORE_PASSWORD
        - name: KAFKA_SASL_JAAS_CONFIG
          valueFrom:
            secretKeyRef:
              name: ${APP_NAME}-secret
              key: KAFKA_SASL_JAAS_CONFIG
        livenessProbe:
          httpGet:
            path: /api/consumer/actuator/health
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/consumer/actuator/health/readiness
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        volumeMounts:
        - name: config-volume
          mountPath: /opt/app/config
        - name: ssl-certs
          mountPath: /opt/kafka/ssl
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: ${APP_NAME}-config
      - name: ssl-certs
        secret:
          secretName: kafka-ssl-certs
      restartPolicy: Always
EOF
}

# Function to create Service manifest
create_service_manifest() {
cat > "$PROJECT_ROOT/k8s/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    component: consumer
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8081"
    prometheus.io/path: "/api/consumer/actuator/prometheus"
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 8081
    targetPort: 8081
    protocol: TCP
  selector:
    app: ${APP_NAME}
---
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-monitoring
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    component: monitoring
spec:
  type: ClusterIP
  ports:
  - name: monitoring
    port: 8081
    targetPort: 8081
    protocol: TCP
  selector:
    app: ${APP_NAME}
EOF
}

# Function to create ServiceMonitor manifest
create_servicemonitor_manifest() {
cat > "$PROJECT_ROOT/k8s/servicemonitor.yaml" << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    component: monitoring
spec:
  selector:
    matchLabels:
      app: ${APP_NAME}
  endpoints:
  - port: http
    path: /api/consumer/actuator/prometheus
    interval: 30s
    scrapeTimeout: 10s
EOF
}

# Function to deploy to Kubernetes
deploy_to_kubernetes() {
    log_info "Deploying to Kubernetes..."
    
    # Apply all manifests
    kubectl apply -f "$PROJECT_ROOT/k8s/"
    
    # Wait for deployment to be ready
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=300s
    
    if [ $? -eq 0 ]; then
        log_success "Deployment completed successfully!"
    else
        log_error "Deployment failed or timed out."
        exit 1
    fi
}

# Function to verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pods
    kubectl get pods -n ${NAMESPACE} -l app=${APP_NAME}
    
    # Check service
    kubectl get service ${APP_NAME} -n ${NAMESPACE}
    
    # Check health endpoint
    log_info "Checking application health..."
    kubectl port-forward service/${APP_NAME} 8081:8081 -n ${NAMESPACE} &
    PF_PID=$!
    
    sleep 5
    
    if curl -f http://localhost:8081/api/consumer/actuator/health; then
        log_success "Application is healthy!"
    else
        log_warning "Health check failed. Check application logs."
    fi
    
    kill $PF_PID 2>/dev/null || true
}

# Function to show logs
show_logs() {
    log_info "Recent application logs:"
    kubectl logs -n ${NAMESPACE} -l app=${APP_NAME} --tail=50
}

# Function to show monitoring information
show_monitoring_info() {
    log_info "Monitoring endpoints:"
    echo "Health: http://localhost:8081/api/consumer/actuator/health"
    echo "Metrics: http://localhost:8081/api/consumer/actuator/metrics"
    echo "Prometheus: http://localhost:8081/api/consumer/actuator/prometheus"
    echo "Monitoring API: http://localhost:8081/api/consumer/monitoring/statistics"
    echo ""
    echo "To access the monitoring endpoints:"
    echo "kubectl port-forward service/${APP_NAME} 8081:8081 -n ${NAMESPACE}"
}

# Function to cleanup deployment
cleanup() {
    log_warning "Cleaning up deployment..."
    kubectl delete -f "$PROJECT_ROOT/k8s/" --ignore-not-found=true
    log_success "Cleanup completed."
}

# Main execution
main() {
    log_info "Starting deployment of KBNT Stock Consumer Service..."
    
    case "${1:-deploy}" in
        "build")
            check_prerequisites
            build_application
            build_docker_image
            ;;
        "deploy")
            check_prerequisites
            create_namespace
            build_application
            build_docker_image
            push_docker_image
            create_kubernetes_manifests
            deploy_to_kubernetes
            verify_deployment
            show_monitoring_info
            ;;
        "verify")
            verify_deployment
            ;;
        "logs")
            show_logs
            ;;
        "cleanup")
            cleanup
            ;;
        "monitoring")
            show_monitoring_info
            ;;
        *)
            echo "Usage: $0 {build|deploy|verify|logs|cleanup|monitoring}"
            echo ""
            echo "Commands:"
            echo "  build      - Build application and Docker image"
            echo "  deploy     - Full deployment pipeline"
            echo "  verify     - Verify existing deployment"
            echo "  logs       - Show application logs"
            echo "  cleanup    - Remove deployment"
            echo "  monitoring - Show monitoring information"
            exit 1
            ;;
    esac
    
    log_success "Operation completed successfully!"
}

# Execute main function with all arguments
main "$@"
