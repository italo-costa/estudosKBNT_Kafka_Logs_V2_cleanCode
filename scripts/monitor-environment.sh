#!/bin/bash

################################################################################
# KBNT Enhanced Kafka Publication Logging System
# Complete Environment Monitoring and Status Check Script
# Version: 1.0.0
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"kbnt-system"}
PRODUCER_PORT=${PRODUCER_PORT:-8080}
CONSUMER_PORT=${CONSUMER_PORT:-8081}
LOG_FILE="/tmp/kbnt-monitoring-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Utility Functions
################################################################################

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${CYAN}[INFO]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "HEADER")
            echo -e "\n${PURPLE}========================================${NC}" | tee -a "$LOG_FILE"
            echo -e "${PURPLE}$message${NC}" | tee -a "$LOG_FILE"
            echo -e "${PURPLE}========================================${NC}" | tee -a "$LOG_FILE"
            ;;
    esac
}

check_command() {
    if command -v $1 &> /dev/null; then
        log "SUCCESS" "✓ $1 is available"
        return 0
    else
        log "ERROR" "✗ $1 is not available"
        return 1
    fi
}

check_k8s_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        local status=$(kubectl get $resource_type $resource_name -n $namespace -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        log "SUCCESS" "✓ $resource_type/$resource_name exists (Status: $status)"
        return 0
    else
        log "ERROR" "✗ $resource_type/$resource_name not found"
        return 1
    fi
}

check_pod_ready() {
    local pod_selector=$1
    local namespace=$2
    
    local ready_pods=$(kubectl get pods -l $pod_selector -n $namespace --no-headers 2>/dev/null | awk '{print $2}' | grep -c "1/1\|2/2\|3/3")
    local total_pods=$(kubectl get pods -l $pod_selector -n $namespace --no-headers 2>/dev/null | wc -l)
    
    if [ "$ready_pods" -gt 0 ] && [ "$total_pods" -gt 0 ]; then
        log "SUCCESS" "✓ $ready_pods/$total_pods pods ready for selector: $pod_selector"
        return 0
    else
        log "ERROR" "✗ 0/$total_pods pods ready for selector: $pod_selector"
        return 1
    fi
}

test_http_endpoint() {
    local url=$1
    local description=$2
    local timeout=${3:-10}
    
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        log "SUCCESS" "✓ $description is accessible ($url)"
        return 0
    else
        log "ERROR" "✗ $description is not accessible ($url)"
        return 1
    fi
}

################################################################################
# Monitoring Functions
################################################################################

check_prerequisites() {
    log "HEADER" "CHECKING PREREQUISITES"
    
    local all_good=true
    
    check_command "kubectl" || all_good=false
    check_command "curl" || all_good=false
    check_command "jq" || all_good=false
    
    # Check Kubernetes connectivity
    if kubectl cluster-info &> /dev/null; then
        log "SUCCESS" "✓ Kubernetes cluster is accessible"
    else
        log "ERROR" "✗ Cannot connect to Kubernetes cluster"
        all_good=false
    fi
    
    # Check namespace
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        log "SUCCESS" "✓ Namespace '$NAMESPACE' exists"
    else
        log "ERROR" "✗ Namespace '$NAMESPACE' not found"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        log "SUCCESS" "All prerequisites are satisfied"
        return 0
    else
        log "ERROR" "Some prerequisites are missing"
        return 1
    fi
}

check_infrastructure() {
    log "HEADER" "CHECKING INFRASTRUCTURE COMPONENTS"
    
    local all_good=true
    
    # Check PostgreSQL
    log "INFO" "Checking PostgreSQL database..."
    check_pod_ready "app=kbnt-postgresql" $NAMESPACE || all_good=false
    
    # Check if PostgreSQL is accessible
    if kubectl exec deployment/kbnt-postgresql -n $NAMESPACE -- pg_isready -U kbnt_user -d kbnt_consumption_db &> /dev/null; then
        log "SUCCESS" "✓ PostgreSQL database is ready and accessible"
    else
        log "ERROR" "✗ PostgreSQL database is not accessible"
        all_good=false
    fi
    
    # Check Kafka Cluster
    log "INFO" "Checking Kafka cluster..."
    if kubectl get kafka kbnt-kafka-cluster -n $NAMESPACE &> /dev/null; then
        local kafka_status=$(kubectl get kafka kbnt-kafka-cluster -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
        if [ "$kafka_status" = "True" ]; then
            log "SUCCESS" "✓ Kafka cluster is ready"
        else
            log "WARNING" "⚠ Kafka cluster status: $kafka_status"
            all_good=false
        fi
    else
        log "ERROR" "✗ Kafka cluster not found"
        all_good=false
    fi
    
    # Check Kafka Topics
    log "INFO" "Checking Kafka topics..."
    local topics=("stock-updates" "high-priority-stock-updates" "stock-updates-retry" "stock-updates-dlt" "publication-logs")
    for topic in "${topics[@]}"; do
        if kubectl get kafkatopic $topic -n $NAMESPACE &> /dev/null; then
            log "SUCCESS" "✓ Topic '$topic' exists"
        else
            log "ERROR" "✗ Topic '$topic' not found"
            all_good=false
        fi
    done
    
    if [ "$all_good" = true ]; then
        log "SUCCESS" "All infrastructure components are healthy"
        return 0
    else
        log "ERROR" "Some infrastructure components have issues"
        return 1
    fi
}

check_application_services() {
    log "HEADER" "CHECKING APPLICATION SERVICES"
    
    local all_good=true
    
    # Check Producer Service
    log "INFO" "Checking Producer Service (Microservice A)..."
    check_pod_ready "app=kbnt-stock-producer-service" $NAMESPACE || all_good=false
    
    # Check Consumer Service
    log "INFO" "Checking Consumer Service (Microservice B)..."
    check_pod_ready "app=kbnt-stock-consumer-service" $NAMESPACE || all_good=false
    
    if [ "$all_good" = true ]; then
        log "SUCCESS" "All application services are running"
        return 0
    else
        log "ERROR" "Some application services have issues"
        return 1
    fi
}

check_service_health() {
    log "HEADER" "CHECKING SERVICE HEALTH ENDPOINTS"
    
    local all_good=true
    
    # Setup port forwarding in background
    log "INFO" "Setting up port forwarding..."
    kubectl port-forward service/kbnt-stock-producer-service $PRODUCER_PORT:8080 -n $NAMESPACE &> /dev/null &
    local producer_pf_pid=$!
    
    kubectl port-forward service/kbnt-stock-consumer-service $CONSUMER_PORT:8081 -n $NAMESPACE &> /dev/null &
    local consumer_pf_pid=$!
    
    # Wait for port forwarding to establish
    sleep 5
    
    # Test Producer Health
    test_http_endpoint "http://localhost:$PRODUCER_PORT/actuator/health" "Producer Service Health" || all_good=false
    test_http_endpoint "http://localhost:$PRODUCER_PORT/actuator/health/readiness" "Producer Service Readiness" || all_good=false
    
    # Test Consumer Health
    test_http_endpoint "http://localhost:$CONSUMER_PORT/api/consumer/actuator/health" "Consumer Service Health" || all_good=false
    test_http_endpoint "http://localhost:$CONSUMER_PORT/api/consumer/actuator/health/readiness" "Consumer Service Readiness" || all_good=false
    
    # Test Consumer Monitoring Endpoints
    test_http_endpoint "http://localhost:$CONSUMER_PORT/api/consumer/monitoring/statistics" "Consumer Monitoring Statistics" || all_good=false
    
    # Cleanup port forwarding
    kill $producer_pf_pid $consumer_pf_pid &> /dev/null
    
    if [ "$all_good" = true ]; then
        log "SUCCESS" "All service health endpoints are accessible"
        return 0
    else
        log "ERROR" "Some service health endpoints are not accessible"
        return 1
    fi
}

test_end_to_end_workflow() {
    log "HEADER" "TESTING END-TO-END WORKFLOW"
    
    # Setup port forwarding
    log "INFO" "Setting up port forwarding for workflow test..."
    kubectl port-forward service/kbnt-stock-producer-service $PRODUCER_PORT:8080 -n $NAMESPACE &> /dev/null &
    local producer_pf_pid=$!
    
    kubectl port-forward service/kbnt-stock-consumer-service $CONSUMER_PORT:8081 -n $NAMESPACE &> /dev/null &
    local consumer_pf_pid=$!
    
    sleep 5
    
    # Generate test message
    local correlation_id="test-$(date +%s)"
    local test_payload='{
        "symbol": "TEST",
        "price": 150.25,
        "volume": 1000,
        "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
        "exchange": "NYSE"
    }'
    
    log "INFO" "Sending test message with correlation ID: $correlation_id"
    
    # Send test message
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "X-Correlation-ID: $correlation_id" \
        -d "$test_payload" \
        "http://localhost:$PRODUCER_PORT/api/stock/update")
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        log "SUCCESS" "✓ Test message sent successfully (HTTP $http_code)"
        
        # Wait for processing
        log "INFO" "Waiting for message processing..."
        sleep 10
        
        # Check consumer statistics
        local stats_response=$(curl -s "http://localhost:$CONSUMER_PORT/api/consumer/monitoring/statistics")
        if echo "$stats_response" | jq -e '.totalMessagesProcessed' &> /dev/null; then
            local processed_count=$(echo "$stats_response" | jq -r '.totalMessagesProcessed')
            log "SUCCESS" "✓ Consumer processed $processed_count messages"
            
            # Check for recent consumption logs
            local logs_response=$(curl -s "http://localhost:$CONSUMER_PORT/api/consumer/monitoring/logs?limit=5")
            if echo "$logs_response" | jq -e '.content | length' &> /dev/null; then
                local log_count=$(echo "$logs_response" | jq -r '.content | length')
                log "SUCCESS" "✓ Found $log_count recent consumption log entries"
                log "SUCCESS" "End-to-end workflow test completed successfully"
            else
                log "WARNING" "⚠ Could not retrieve consumption logs"
            fi
        else
            log "ERROR" "✗ Could not retrieve consumer statistics"
        fi
    else
        log "ERROR" "✗ Failed to send test message (HTTP $http_code)"
        log "ERROR" "Response: $response_body"
    fi
    
    # Cleanup port forwarding
    kill $producer_pf_pid $consumer_pf_pid &> /dev/null
}

get_system_metrics() {
    log "HEADER" "COLLECTING SYSTEM METRICS"
    
    # Kubernetes Resources
    log "INFO" "Kubernetes Resource Usage:"
    kubectl top nodes 2>/dev/null || log "WARNING" "⚠ Metrics server not available for node metrics"
    kubectl top pods -n $NAMESPACE 2>/dev/null || log "WARNING" "⚠ Metrics server not available for pod metrics"
    
    # Service Status Summary
    log "INFO" "Service Status Summary:"
    kubectl get pods,services,deployments -n $NAMESPACE
    
    # Kafka Topics Status
    log "INFO" "Kafka Topics Status:"
    kubectl get kafkatopics -n $NAMESPACE
    
    # Recent Pod Events
    log "INFO" "Recent Pod Events:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
}

display_service_urls() {
    log "HEADER" "SERVICE ACCESS INFORMATION"
    
    log "INFO" "Service URLs (after port forwarding):"
    echo -e "${CYAN}Producer Service:${NC}"
    echo -e "  Health:        http://localhost:$PRODUCER_PORT/actuator/health"
    echo -e "  API:           http://localhost:$PRODUCER_PORT/api/stock/update"
    echo -e "  Metrics:       http://localhost:$PRODUCER_PORT/actuator/metrics"
    echo -e "  Prometheus:    http://localhost:$PRODUCER_PORT/actuator/prometheus"
    
    echo -e "\n${CYAN}Consumer Service:${NC}"
    echo -e "  Health:        http://localhost:$CONSUMER_PORT/api/consumer/actuator/health"
    echo -e "  Statistics:    http://localhost:$CONSUMER_PORT/api/consumer/monitoring/statistics"
    echo -e "  Logs:          http://localhost:$CONSUMER_PORT/api/consumer/monitoring/logs"
    echo -e "  Errors:        http://localhost:$CONSUMER_PORT/api/consumer/monitoring/errors/api"
    echo -e "  Performance:   http://localhost:$CONSUMER_PORT/api/consumer/monitoring/performance/slowest"
    
    echo -e "\n${CYAN}Port Forwarding Commands:${NC}"
    echo -e "  Producer:      kubectl port-forward service/kbnt-stock-producer-service $PRODUCER_PORT:8080 -n $NAMESPACE"
    echo -e "  Consumer:      kubectl port-forward service/kbnt-stock-consumer-service $CONSUMER_PORT:8081 -n $NAMESPACE"
}

################################################################################
# Main Function
################################################################################

main() {
    local command=${1:-"full"}
    
    log "HEADER" "KBNT Enhanced Kafka Publication Logging System - Monitoring"
    log "INFO" "Monitoring started at $(date)"
    log "INFO" "Namespace: $NAMESPACE"
    log "INFO" "Log file: $LOG_FILE"
    
    case $command in
        "prerequisites")
            check_prerequisites
            ;;
        "infrastructure")
            check_infrastructure
            ;;
        "services")
            check_application_services
            ;;
        "health")
            check_service_health
            ;;
        "test")
            test_end_to_end_workflow
            ;;
        "metrics")
            get_system_metrics
            ;;
        "urls")
            display_service_urls
            ;;
        "full")
            check_prerequisites && \
            check_infrastructure && \
            check_application_services && \
            check_service_health && \
            test_end_to_end_workflow && \
            get_system_metrics && \
            display_service_urls
            ;;
        *)
            echo "Usage: $0 [prerequisites|infrastructure|services|health|test|metrics|urls|full]"
            exit 1
            ;;
    esac
    
    log "INFO" "Monitoring completed at $(date)"
    log "INFO" "Full log available at: $LOG_FILE"
}

################################################################################
# Script Execution
################################################################################

main "$@"
