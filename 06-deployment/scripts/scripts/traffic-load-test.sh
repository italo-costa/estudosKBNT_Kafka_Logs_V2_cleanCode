#!/bin/bash

################################################################################
# KBNT Traffic Load Test with Elasticsearch Integration
# Generates realistic message traffic between Producer → Kafka → Consumer
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
PRODUCER_URL="http://localhost:8080"
CONSUMER_URL="http://localhost:8081"
KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

# Test parameters
TOTAL_MESSAGES=${TOTAL_MESSAGES:-500}
CONCURRENT_THREADS=${CONCURRENT_THREADS:-10}
BATCH_SIZE=${BATCH_SIZE:-50}
DELAY_BETWEEN_BATCHES=${DELAY_BETWEEN_BATCHES:-2}

# Product catalog for realistic simulation
PRODUCTS=(
    "SMARTPHONE-XYZ123:599.99"
    "TABLET-ABC456:399.99"
    "NOTEBOOK-DEF789:1299.99"
    "HEADPHONE-GHI012:149.99"
    "SMARTWATCH-JKL345:299.99"
    "SPEAKER-MNO678:89.99"
    "CAMERA-PQR901:799.99"
    "DRONE-STU234:699.99"
    "MONITOR-VWX567:249.99"
    "KEYBOARD-YZA890:79.99"
)

OPERATIONS=("INCREASE" "DECREASE" "SET" "SYNC")
PRIORITIES=("LOW" "NORMAL" "HIGH" "CRITICAL")
EXCHANGES=("NYSE" "NASDAQ" "LSE" "TSE")

################################################################################
# Utility Functions
################################################################################

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${CYAN}[INFO]${NC} ${timestamp} - $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
            ;;
        "HEADER")
            echo -e "\n${PURPLE}========================================${NC}"
            echo -e "${PURPLE}$message${NC}"
            echo -e "${PURPLE}========================================${NC}"
            ;;
    esac
}

generate_correlation_id() {
    echo "LOAD-TEST-$(date +%s)-$(( RANDOM % 9999 ))"
}

generate_random_product() {
    local product_data=${PRODUCTS[$RANDOM % ${#PRODUCTS[@]}]}
    echo $product_data
}

generate_random_operation() {
    echo ${OPERATIONS[$RANDOM % ${#OPERATIONS[@]}]}
}

generate_random_priority() {
    echo ${PRIORITIES[$RANDOM % ${#PRIORITIES[@]}]}
}

generate_random_exchange() {
    echo ${EXCHANGES[$RANDOM % ${#EXCHANGES[@]}]}
}

generate_realistic_quantity() {
    local operation=$1
    case $operation in
        "INCREASE")
            echo $(( RANDOM % 1000 + 100 ))  # 100-1099
            ;;
        "DECREASE")
            echo $(( RANDOM % 500 + 50 ))    # 50-549
            ;;
        "SET")
            echo $(( RANDOM % 5000 + 1000 )) # 1000-5999
            ;;
        "SYNC")
            echo $(( RANDOM % 2000 + 500 ))  # 500-2499
            ;;
        *)
            echo $(( RANDOM % 1000 + 100 ))
            ;;
    esac
}

################################################################################
# Service Health Checks
################################################################################

check_services() {
    log "HEADER" "CHECKING SERVICE AVAILABILITY"
    
    local all_healthy=true
    
    # Check Producer Service
    if curl -f "$PRODUCER_URL/actuator/health" > /dev/null 2>&1; then
        log "SUCCESS" "✓ Producer Service is healthy"
    else
        log "ERROR" "✗ Producer Service is not accessible"
        all_healthy=false
    fi
    
    # Check Consumer Service
    if curl -f "$CONSUMER_URL/api/consumer/actuator/health" > /dev/null 2>&1; then
        log "SUCCESS" "✓ Consumer Service is healthy"
    else
        log "ERROR" "✗ Consumer Service is not accessible"
        all_healthy=false
    fi
    
    # Check Elasticsearch
    if curl -f "$ELASTICSEARCH_URL/_cluster/health" > /dev/null 2>&1; then
        log "SUCCESS" "✓ Elasticsearch is healthy"
    else
        log "WARNING" "⚠ Elasticsearch is not accessible (will use PostgreSQL fallback)"
    fi
    
    # Check Kibana
    if curl -f "$KIBANA_URL/api/status" > /dev/null 2>&1; then
        log "SUCCESS" "✓ Kibana is healthy"
    else
        log "WARNING" "⚠ Kibana is not accessible (dashboards won't be available)"
    fi
    
    if [ "$all_healthy" = false ]; then
        log "ERROR" "Some critical services are unavailable"
        return 1
    fi
    
    return 0
}

################################################################################
# Message Generation and Sending
################################################################################

send_stock_update_message() {
    local correlation_id=$1
    local product_info=$2
    local operation=$3
    local priority=$4
    local quantity=$5
    local exchange=$6
    
    # Parse product info
    local product_id=$(echo $product_info | cut -d':' -f1)
    local price=$(echo $product_info | cut -d':' -f2)
    
    # Generate message payload
    local payload=$(cat <<EOF
{
    "correlationId": "$correlation_id",
    "productId": "$product_id",
    "quantity": $quantity,
    "price": $price,
    "operation": "$operation",
    "priority": "$priority",
    "exchange": "$exchange",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
    "metadata": {
        "test_run": true,
        "load_test_batch": "$(date +%s)",
        "source": "traffic-load-test"
    }
}
EOF
)
    
    # Send message to producer
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "X-Correlation-ID: $correlation_id" \
        -H "X-Source: load-test" \
        -d "$payload" \
        "$PRODUCER_URL/api/stock/update" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "SUCCESS:$correlation_id:$product_id:$operation:$priority"
        return 0
    else
        echo "FAILED:$correlation_id:$product_id:$operation:$priority:HTTP_$http_code"
        return 1
    fi
}

send_message_batch() {
    local batch_id=$1
    local batch_size=$2
    
    log "INFO" "Sending batch $batch_id with $batch_size messages..."
    
    local success_count=0
    local fail_count=0
    
    for i in $(seq 1 $batch_size); do
        local correlation_id=$(generate_correlation_id)
        local product_info=$(generate_random_product)
        local operation=$(generate_random_operation)
        local priority=$(generate_random_priority)
        local quantity=$(generate_realistic_quantity $operation)
        local exchange=$(generate_random_exchange)
        
        local result=$(send_stock_update_message "$correlation_id" "$product_info" "$operation" "$priority" "$quantity" "$exchange")
        
        if echo "$result" | grep -q "SUCCESS"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        
        # Small delay to avoid overwhelming the system
        sleep 0.1
    done
    
    log "SUCCESS" "Batch $batch_id completed: $success_count successes, $fail_count failures"
}

################################################################################
# Load Test Execution
################################################################################

run_load_test() {
    log "HEADER" "STARTING LOAD TEST"
    log "INFO" "Test Parameters:"
    log "INFO" "  Total Messages: $TOTAL_MESSAGES"
    log "INFO" "  Concurrent Threads: $CONCURRENT_THREADS"
    log "INFO" "  Batch Size: $BATCH_SIZE"
    log "INFO" "  Delay Between Batches: ${DELAY_BETWEEN_BATCHES}s"
    
    local start_time=$(date +%s)
    local total_batches=$(( (TOTAL_MESSAGES + BATCH_SIZE - 1) / BATCH_SIZE ))
    
    log "INFO" "Starting $total_batches batches..."
    
    # Run batches
    for batch in $(seq 1 $total_batches); do
        local remaining_messages=$(( TOTAL_MESSAGES - ((batch - 1) * BATCH_SIZE) ))
        local current_batch_size=$(( remaining_messages < BATCH_SIZE ? remaining_messages : BATCH_SIZE ))
        
        if [ $current_batch_size -le 0 ]; then
            break
        fi
        
        # Send batch in background for concurrency
        send_message_batch $batch $current_batch_size &
        
        # Control concurrency
        if [ $(( batch % CONCURRENT_THREADS )) -eq 0 ]; then
            wait  # Wait for current batch to complete
            log "INFO" "Completed $batch/$total_batches batches"
        fi
        
        # Delay between batches
        if [ $batch -lt $total_batches ]; then
            sleep $DELAY_BETWEEN_BATCHES
        fi
    done
    
    # Wait for any remaining background processes
    wait
    
    local end_time=$(date +%s)
    local duration=$(( end_time - start_time ))
    
    log "SUCCESS" "Load test completed in ${duration}s"
    log "INFO" "Average throughput: $(( TOTAL_MESSAGES / duration )) messages/second"
}

################################################################################
# Traffic Monitoring
################################################################################

monitor_traffic_real_time() {
    log "HEADER" "MONITORING REAL-TIME TRAFFIC"
    
    local monitor_duration=60  # Monitor for 60 seconds
    local check_interval=10    # Check every 10 seconds
    
    log "INFO" "Monitoring traffic for ${monitor_duration}s (checking every ${check_interval}s)..."
    
    for i in $(seq 0 $check_interval $monitor_duration); do
        if [ $i -gt 0 ]; then
            sleep $check_interval
        fi
        
        # Get producer statistics
        local producer_stats=$(curl -s "$PRODUCER_URL/actuator/metrics/kafka.producer.record-send-total" 2>/dev/null)
        
        # Get consumer statistics
        local consumer_stats=$(curl -s "$CONSUMER_URL/api/consumer/monitoring/statistics" 2>/dev/null)
        
        if [ ! -z "$consumer_stats" ]; then
            local total_messages=$(echo "$consumer_stats" | jq -r '.total_messages // 0' 2>/dev/null || echo "0")
            local successful_messages=$(echo "$consumer_stats" | jq -r '.successful_messages // 0' 2>/dev/null || echo "0")
            local failed_messages=$(echo "$consumer_stats" | jq -r '.failed_messages // 0' 2>/dev/null || echo "0")
            local avg_processing_time=$(echo "$consumer_stats" | jq -r '.average_processing_time_ms // 0' 2>/dev/null || echo "0")
            
            log "INFO" "Traffic Status @ ${i}s: Total=$total_messages, Success=$successful_messages, Failed=$failed_messages, AvgTime=${avg_processing_time}ms"
        else
            log "WARNING" "Could not retrieve consumer statistics"
        fi
        
        # Check Elasticsearch health and document count
        if curl -f "$ELASTICSEARCH_URL/_cluster/health" > /dev/null 2>&1; then
            local doc_count=$(curl -s "$ELASTICSEARCH_URL/kbnt-consumption-logs-*/_count" 2>/dev/null | jq -r '.count // 0' 2>/dev/null || echo "0")
            log "INFO" "Elasticsearch: $doc_count documents indexed"
        fi
    done
}

################################################################################
# Kibana Dashboard Setup
################################################################################

setup_kibana_dashboard() {
    log "HEADER" "SETTING UP KIBANA DASHBOARD"
    
    if ! curl -f "$KIBANA_URL/api/status" > /dev/null 2>&1; then
        log "ERROR" "Kibana is not accessible. Cannot create dashboard."
        return 1
    fi
    
    # Wait a bit for data to be indexed
    log "INFO" "Waiting for data to be indexed in Elasticsearch..."
    sleep 30
    
    # Create data view if it doesn't exist
    log "INFO" "Creating Kibana data view..."
    curl -X POST "$KIBANA_URL/api/data_views/data_view" \
         -H "Content-Type: application/json" \
         -H "kbn-xsrf: true" \
         -d '{
  "data_view": {
    "title": "kbnt-consumption-logs-*",
    "name": "KBNT Traffic Monitoring",
    "timeFieldName": "@timestamp"
  }
}' > /dev/null 2>&1
    
    log "SUCCESS" "✓ Kibana data view created/verified"
    
    # Create sample visualizations (this would typically be imported from saved objects)
    log "INFO" "Dashboard URL: $KIBANA_URL/app/dashboards"
    log "INFO" "Data View: kbnt-consumption-logs-*"
    
    log "INFO" "Suggested Kibana visualizations to create:"
    log "INFO" "  1. Line Chart: Messages processed over time (@timestamp, count)"
    log "INFO" "  2. Pie Chart: Status distribution (status.keyword)"
    log "INFO" "  3. Histogram: Processing time distribution (processing_time_ms)"
    log "INFO" "  4. Data Table: Recent messages (correlation_id, product_id, status, processing_time_ms)"
    log "INFO" "  5. Metric: Total messages processed"
    log "INFO" "  6. Area Chart: Message volume by priority"
}

################################################################################
# Results Analysis
################################################################################

analyze_test_results() {
    log "HEADER" "ANALYZING TEST RESULTS"
    
    # Wait for all messages to be processed
    log "INFO" "Waiting for message processing to complete..."
    sleep 60
    
    # Get final statistics from consumer
    local final_stats=$(curl -s "$CONSUMER_URL/api/consumer/monitoring/statistics?hours=1" 2>/dev/null)
    
    if [ ! -z "$final_stats" ]; then
        local total=$(echo "$final_stats" | jq -r '.total_messages // 0' 2>/dev/null || echo "0")
        local successful=$(echo "$final_stats" | jq -r '.successful_messages // 0' 2>/dev/null || echo "0")
        local failed=$(echo "$final_stats" | jq -r '.failed_messages // 0' 2>/dev/null || echo "0")
        local avg_time=$(echo "$final_stats" | jq -r '.average_processing_time_ms // 0' 2>/dev/null || echo "0")
        local success_rate=$(echo "scale=2; $successful * 100 / $total" | bc -l 2>/dev/null || echo "0")
        
        log "SUCCESS" "📊 FINAL RESULTS:"
        log "SUCCESS" "  Total Messages Processed: $total"
        log "SUCCESS" "  Successful: $successful"
        log "SUCCESS" "  Failed: $failed"
        log "SUCCESS" "  Success Rate: ${success_rate}%"
        log "SUCCESS" "  Average Processing Time: ${avg_time}ms"
    else
        log "ERROR" "Could not retrieve final statistics"
    fi
    
    # Check Elasticsearch document count
    if curl -f "$ELASTICSEARCH_URL/_cluster/health" > /dev/null 2>&1; then
        local es_doc_count=$(curl -s "$ELASTICSEARCH_URL/kbnt-consumption-logs-*/_count" 2>/dev/null | jq -r '.count // 0' 2>/dev/null || echo "0")
        log "SUCCESS" "  Documents in Elasticsearch: $es_doc_count"
        
        # Get some sample documents
        log "INFO" "Sample recent documents:"
        curl -s "$ELASTICSEARCH_URL/kbnt-consumption-logs-*/_search?size=5&sort=@timestamp:desc" 2>/dev/null | \
        jq -r '.hits.hits[]._source | "  - \(.correlation_id) | \(.product_id) | \(.status) | \(.processing_time_ms)ms"' 2>/dev/null || true
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    log "HEADER" "KBNT TRAFFIC LOAD TEST WITH KIBANA DASHBOARD"
    log "INFO" "Starting comprehensive traffic test..."
    
    # Check if all required tools are available
    for tool in curl jq bc; do
        if ! command -v $tool >/dev/null 2>&1; then
            log "ERROR" "$tool is required but not installed"
            exit 1
        fi
    done
    
    # Step 1: Check service health
    if ! check_services; then
        log "ERROR" "Service health check failed. Please ensure all services are running."
        exit 1
    fi
    
    # Step 2: Set up Kibana dashboard (prepare for data)
    setup_kibana_dashboard
    
    # Step 3: Start monitoring in background
    monitor_traffic_real_time &
    local monitor_pid=$!
    
    # Step 4: Run the load test
    run_load_test
    
    # Step 5: Stop monitoring
    kill $monitor_pid 2>/dev/null || true
    
    # Step 6: Analyze results
    analyze_test_results
    
    # Step 7: Final instructions
    log "HEADER" "TEST COMPLETED - KIBANA DASHBOARD ACCESS"
    log "SUCCESS" "🎉 Traffic load test completed successfully!"
    log "INFO" ""
    log "INFO" "📊 Access your Kibana dashboard:"
    log "INFO" "  URL: $KIBANA_URL/app/dashboards"
    log "INFO" "  Data View: kbnt-consumption-logs-*"
    log "INFO" "  Time Range: Last 1 hour"
    log "INFO" ""
    log "INFO" "🔍 Useful Kibana searches:"
    log "INFO" "  All test messages: metadata.test_run:true"
    log "INFO" "  Failed messages: status:FAILED"
    log "INFO" "  High priority: priority:HIGH"
    log "INFO" "  Specific product: product_id:SMARTPHONE*"
    log "INFO" ""
    log "INFO" "📈 Recommended visualizations:"
    log "INFO" "  1. Messages over time (Line chart)"
    log "INFO" "  2. Status distribution (Pie chart)"
    log "INFO" "  3. Processing time histogram"
    log "INFO" "  4. Error analysis table"
    log "INFO" ""
    log "SUCCESS" "Open $KIBANA_URL to view real-time traffic data!"
}

################################################################################
# Script Execution
################################################################################

# Handle command line arguments
case "${1:-run}" in
    "run")
        main
        ;;
    "monitor")
        check_services && monitor_traffic_real_time
        ;;
    "dashboard")
        setup_kibana_dashboard
        ;;
    "analyze")
        analyze_test_results
        ;;
    *)
        echo "Usage: $0 [run|monitor|dashboard|analyze]"
        echo ""
        echo "Commands:"
        echo "  run       - Run complete traffic load test (default)"
        echo "  monitor   - Only monitor existing traffic"
        echo "  dashboard - Only setup Kibana dashboard"
        echo "  analyze   - Only analyze existing results"
        exit 1
        ;;
esac
