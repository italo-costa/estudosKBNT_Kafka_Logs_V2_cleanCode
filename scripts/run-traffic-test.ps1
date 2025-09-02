# KBNT Traffic Test and Kibana Dashboard Automation Script
# PowerShell script to run comprehensive traffic test and open Kibana dashboard

param(
    [int]$TotalMessages = 500,
    [int]$ConcurrentThreads = 10,
    [int]$BatchSize = 50,
    [int]$DelayBetweenBatches = 2,
    [switch]$SkipTest,
    [switch]$OpenKibana,
    [switch]$Help
)

# Configuration
$PRODUCER_URL = "http://localhost:8080"
$CONSUMER_URL = "http://localhost:8081"
$KIBANA_URL = "http://localhost:5601"
$ELASTICSEARCH_URL = "http://localhost:9200"

# Colors for PowerShell output
$Colors = @{
    Info = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Header = "Magenta"
}

function Write-ColoredLog {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "INFO" { Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $Colors.Info }
        "SUCCESS" { Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $Colors.Success }
        "WARNING" { Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $Colors.Warning }
        "ERROR" { Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $Colors.Error }
        "HEADER" {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor $Colors.Header
            Write-Host $Message -ForegroundColor $Colors.Header
            Write-Host "========================================" -ForegroundColor $Colors.Header
        }
    }
}

function Test-ServiceHealth {
    Write-ColoredLog "HEADER" "CHECKING SERVICE AVAILABILITY"
    
    $allHealthy = $true
    
    # Test Producer Service
    try {
        $response = Invoke-WebRequest -Uri "$PRODUCER_URL/actuator/health" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColoredLog "SUCCESS" "✓ Producer Service is healthy"
        } else {
            Write-ColoredLog "ERROR" "✗ Producer Service returned status $($response.StatusCode)"
            $allHealthy = $false
        }
    } catch {
        Write-ColoredLog "ERROR" "✗ Producer Service is not accessible: $($_.Exception.Message)"
        $allHealthy = $false
    }
    
    # Test Consumer Service
    try {
        $response = Invoke-WebRequest -Uri "$CONSUMER_URL/api/consumer/actuator/health" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColoredLog "SUCCESS" "✓ Consumer Service is healthy"
        } else {
            Write-ColoredLog "ERROR" "✗ Consumer Service returned status $($response.StatusCode)"
            $allHealthy = $false
        }
    } catch {
        Write-ColoredLog "ERROR" "✗ Consumer Service is not accessible: $($_.Exception.Message)"
        $allHealthy = $false
    }
    
    # Test Elasticsearch
    try {
        $response = Invoke-WebRequest -Uri "$ELASTICSEARCH_URL/_cluster/health" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColoredLog "SUCCESS" "✓ Elasticsearch is healthy"
        } else {
            Write-ColoredLog "WARNING" "⚠ Elasticsearch returned status $($response.StatusCode)"
        }
    } catch {
        Write-ColoredLog "WARNING" "⚠ Elasticsearch is not accessible: $($_.Exception.Message)"
    }
    
    # Test Kibana
    try {
        $response = Invoke-WebRequest -Uri "$KIBANA_URL/api/status" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColoredLog "SUCCESS" "✓ Kibana is healthy"
        } else {
            Write-ColoredLog "WARNING" "⚠ Kibana returned status $($response.StatusCode)"
        }
    } catch {
        Write-ColoredLog "WARNING" "⚠ Kibana is not accessible: $($_.Exception.Message)"
    }
    
    return $allHealthy
}

function Start-ElasticsearchStack {
    Write-ColoredLog "HEADER" "STARTING ELASTICSEARCH STACK"
    
    $dockerComposeFile = "c:\workspace\estudosKBNT_Kafka_Logs\alternatives\docker-compose-elasticsearch.yml"
    
    if (-not (Test-Path $dockerComposeFile)) {
        Write-ColoredLog "ERROR" "Docker Compose file not found: $dockerComposeFile"
        return $false
    }
    
    Write-ColoredLog "INFO" "Starting Elasticsearch stack with Docker Compose..."
    
    try {
        # Start the stack
        $result = docker-compose -f $dockerComposeFile up -d
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredLog "SUCCESS" "✓ Elasticsearch stack started successfully"
            
            # Wait for services to be ready
            Write-ColoredLog "INFO" "Waiting for services to initialize..."
            Start-Sleep -Seconds 60
            
            # Run setup script if available
            $setupScript = "c:\workspace\estudosKBNT_Kafka_Logs\alternatives\setup-elasticsearch.sh"
            if (Test-Path $setupScript) {
                Write-ColoredLog "INFO" "Running Elasticsearch setup..."
                bash $setupScript setup
            }
            
            return $true
        } else {
            Write-ColoredLog "ERROR" "Failed to start Elasticsearch stack"
            return $false
        }
    } catch {
        Write-ColoredLog "ERROR" "Error starting Elasticsearch stack: $($_.Exception.Message)"
        return $false
    }
}

function Send-StockUpdateMessage {
    param(
        [string]$CorrelationId,
        [string]$ProductId,
        [decimal]$Price,
        [string]$Operation,
        [string]$Priority,
        [int]$Quantity,
        [string]$Exchange
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $batchTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    
    $payload = @{
        correlationId = $CorrelationId
        productId = $ProductId
        quantity = $Quantity
        price = $Price
        operation = $Operation
        priority = $Priority
        exchange = $Exchange
        timestamp = $timestamp
        metadata = @{
            test_run = $true
            load_test_batch = $batchTimestamp
            source = "traffic-load-test-powershell"
        }
    } | ConvertTo-Json -Depth 3
    
    $headers = @{
        "Content-Type" = "application/json"
        "X-Correlation-ID" = $CorrelationId
        "X-Source" = "load-test-powershell"
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$PRODUCER_URL/api/stock/update" -Method POST -Body $payload -Headers $headers -TimeoutSec 30
        
        if ($response.StatusCode -in @(200, 201)) {
            return @{ Success = $true; CorrelationId = $CorrelationId; ProductId = $ProductId }
        } else {
            return @{ Success = $false; CorrelationId = $CorrelationId; ProductId = $ProductId; Error = "HTTP $($response.StatusCode)" }
        }
    } catch {
        return @{ Success = $false; CorrelationId = $CorrelationId; ProductId = $ProductId; Error = $_.Exception.Message }
    }
}

function Start-LoadTest {
    Write-ColoredLog "HEADER" "STARTING LOAD TEST"
    Write-ColoredLog "INFO" "Test Parameters:"
    Write-ColoredLog "INFO" "  Total Messages: $TotalMessages"
    Write-ColoredLog "INFO" "  Concurrent Threads: $ConcurrentThreads"
    Write-ColoredLog "INFO" "  Batch Size: $BatchSize"
    Write-ColoredLog "INFO" "  Delay Between Batches: ${DelayBetweenBatches}s"
    
    # Product catalog
    $products = @(
        @{ Id = "SMARTPHONE-XYZ123"; Price = 599.99 },
        @{ Id = "TABLET-ABC456"; Price = 399.99 },
        @{ Id = "NOTEBOOK-DEF789"; Price = 1299.99 },
        @{ Id = "HEADPHONE-GHI012"; Price = 149.99 },
        @{ Id = "SMARTWATCH-JKL345"; Price = 299.99 },
        @{ Id = "SPEAKER-MNO678"; Price = 89.99 },
        @{ Id = "CAMERA-PQR901"; Price = 799.99 },
        @{ Id = "DRONE-STU234"; Price = 699.99 },
        @{ Id = "MONITOR-VWX567"; Price = 249.99 },
        @{ Id = "KEYBOARD-YZA890"; Price = 79.99 }
    )
    
    $operations = @("INCREASE", "DECREASE", "SET", "SYNC")
    $priorities = @("LOW", "NORMAL", "HIGH", "CRITICAL")
    $exchanges = @("NYSE", "NASDAQ", "LSE", "TSE")
    
    $startTime = Get-Date
    $totalBatches = [Math]::Ceiling($TotalMessages / $BatchSize)
    $successCount = 0
    $failCount = 0
    
    Write-ColoredLog "INFO" "Starting $totalBatches batches..."
    
    # Create jobs for parallel processing
    $jobs = @()
    
    for ($batch = 1; $batch -le $totalBatches; $batch++) {
        $remainingMessages = $TotalMessages - (($batch - 1) * $BatchSize)
        $currentBatchSize = [Math]::Min($remainingMessages, $BatchSize)
        
        if ($currentBatchSize -le 0) { break }
        
        # Create job for this batch
        $job = Start-Job -ScriptBlock {
            param($BatchId, $BatchSize, $Products, $Operations, $Priorities, $Exchanges, $ProducerUrl)
            
            $results = @()
            
            for ($i = 1; $i -le $BatchSize; $i++) {
                $correlationId = "LOAD-TEST-$(Get-Date -UFormat %s)-$(Get-Random -Maximum 9999)"
                $product = $Products | Get-Random
                $operation = $Operations | Get-Random
                $priority = $Priorities | Get-Random
                $exchange = $Exchanges | Get-Random
                
                # Generate realistic quantity based on operation
                switch ($operation) {
                    "INCREASE" { $quantity = Get-Random -Minimum 100 -Maximum 1100 }
                    "DECREASE" { $quantity = Get-Random -Minimum 50 -Maximum 550 }
                    "SET" { $quantity = Get-Random -Minimum 1000 -Maximum 6000 }
                    "SYNC" { $quantity = Get-Random -Minimum 500 -Maximum 2500 }
                    default { $quantity = Get-Random -Minimum 100 -Maximum 1100 }
                }
                
                $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
                $batchTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
                
                $payload = @{
                    correlationId = $correlationId
                    productId = $product.Id
                    quantity = $quantity
                    price = $product.Price
                    operation = $operation
                    priority = $priority
                    exchange = $exchange
                    timestamp = $timestamp
                    metadata = @{
                        test_run = $true
                        load_test_batch = $batchTimestamp
                        source = "traffic-load-test-powershell"
                    }
                } | ConvertTo-Json -Depth 3
                
                $headers = @{
                    "Content-Type" = "application/json"
                    "X-Correlation-ID" = $correlationId
                    "X-Source" = "load-test-powershell"
                }
                
                try {
                    $response = Invoke-WebRequest -Uri "$ProducerUrl/api/stock/update" -Method POST -Body $payload -Headers $headers -TimeoutSec 30
                    
                    if ($response.StatusCode -in @(200, 201)) {
                        $results += @{ Success = $true; CorrelationId = $correlationId; ProductId = $product.Id }
                    } else {
                        $results += @{ Success = $false; CorrelationId = $correlationId; ProductId = $product.Id; Error = "HTTP $($response.StatusCode)" }
                    }
                } catch {
                    $results += @{ Success = $false; CorrelationId = $correlationId; ProductId = $product.Id; Error = $_.Exception.Message }
                }
                
                Start-Sleep -Milliseconds 100  # Small delay to avoid overwhelming
            }
            
            return @{ BatchId = $BatchId; Results = $results }
        } -ArgumentList $batch, $currentBatchSize, $products, $operations, $priorities, $exchanges, $PRODUCER_URL
        
        $jobs += $job
        
        # Control concurrency
        if ($jobs.Count -ge $ConcurrentThreads) {
            # Wait for some jobs to complete
            $completed = $jobs | Where-Object { $_.State -eq "Completed" }
            
            foreach ($completedJob in $completed) {
                $result = Receive-Job -Job $completedJob
                $batchSuccess = ($result.Results | Where-Object { $_.Success }).Count
                $batchFail = ($result.Results | Where-Object { -not $_.Success }).Count
                
                $successCount += $batchSuccess
                $failCount += $batchFail
                
                Write-ColoredLog "SUCCESS" "Batch $($result.BatchId) completed: $batchSuccess successes, $batchFail failures"
                
                Remove-Job -Job $completedJob
            }
            
            $jobs = $jobs | Where-Object { $_.State -ne "Completed" }
        }
        
        Write-ColoredLog "INFO" "Started batch $batch/$totalBatches"
        
        if ($batch -lt $totalBatches) {
            Start-Sleep -Seconds $DelayBetweenBatches
        }
    }
    
    # Wait for all remaining jobs to complete
    Write-ColoredLog "INFO" "Waiting for remaining batches to complete..."
    $jobs | Wait-Job | ForEach-Object {
        $result = Receive-Job -Job $_
        $batchSuccess = ($result.Results | Where-Object { $_.Success }).Count
        $batchFail = ($result.Results | Where-Object { -not $_.Success }).Count
        
        $successCount += $batchSuccess
        $failCount += $batchFail
        
        Write-ColoredLog "SUCCESS" "Batch $($result.BatchId) completed: $batchSuccess successes, $batchFail failures"
        
        Remove-Job -Job $_
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    $throughput = [Math]::Round($TotalMessages / $duration, 2)
    
    Write-ColoredLog "SUCCESS" "Load test completed in ${duration}s"
    Write-ColoredLog "INFO" "Total: $TotalMessages messages, Success: $successCount, Failed: $failCount"
    Write-ColoredLog "INFO" "Average throughput: $throughput messages/second"
    
    return @{
        TotalMessages = $TotalMessages
        SuccessCount = $successCount
        FailCount = $failCount
        Duration = $duration
        Throughput = $throughput
    }
}

function Setup-KibanaDashboard {
    Write-ColoredLog "HEADER" "SETTING UP KIBANA DASHBOARD"
    
    try {
        $response = Invoke-WebRequest -Uri "$KIBANA_URL/api/status" -Method GET -TimeoutSec 10
        if ($response.StatusCode -ne 200) {
            Write-ColoredLog "ERROR" "Kibana is not accessible. Status: $($response.StatusCode)"
            return $false
        }
    } catch {
        Write-ColoredLog "ERROR" "Kibana is not accessible: $($_.Exception.Message)"
        return $false
    }
    
    Write-ColoredLog "INFO" "Waiting for data to be indexed in Elasticsearch..."
    Start-Sleep -Seconds 30
    
    # Create data view
    Write-ColoredLog "INFO" "Creating Kibana data view..."
    
    $dataViewPayload = @{
        data_view = @{
            title = "kbnt-consumption-logs-*"
            name = "KBNT Traffic Monitoring"
            timeFieldName = "@timestamp"
        }
    } | ConvertTo-Json -Depth 3
    
    $headers = @{
        "Content-Type" = "application/json"
        "kbn-xsrf" = "true"
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$KIBANA_URL/api/data_views/data_view" -Method POST -Body $dataViewPayload -Headers $headers -TimeoutSec 30
        Write-ColoredLog "SUCCESS" "✓ Kibana data view created/verified"
    } catch {
        Write-ColoredLog "WARNING" "Could not create data view: $($_.Exception.Message)"
    }
    
    # Import dashboard if available
    $dashboardFile = "c:\workspace\estudosKBNT_Kafka_Logs\alternatives\kibana\dashboard-export.json"
    if (Test-Path $dashboardFile) {
        Write-ColoredLog "INFO" "Importing Kibana dashboard..."
        try {
            $dashboardContent = Get-Content -Path $dashboardFile -Raw | ConvertFrom-Json
            $importPayload = $dashboardContent | ConvertTo-Json -Depth 10
            
            $response = Invoke-WebRequest -Uri "$KIBANA_URL/api/saved_objects/_import" -Method POST -Body $importPayload -Headers $headers -TimeoutSec 30
            Write-ColoredLog "SUCCESS" "✓ Dashboard imported successfully"
        } catch {
            Write-ColoredLog "WARNING" "Could not import dashboard: $($_.Exception.Message)"
        }
    }
    
    Write-ColoredLog "INFO" "Dashboard URL: $KIBANA_URL/app/dashboards"
    Write-ColoredLog "INFO" "Data View: kbnt-consumption-logs-*"
    
    return $true
}

function Show-TestResults {
    Write-ColoredLog "HEADER" "ANALYZING TEST RESULTS"
    
    # Wait for processing to complete
    Write-ColoredLog "INFO" "Waiting for message processing to complete..."
    Start-Sleep -Seconds 60
    
    try {
        $statsResponse = Invoke-WebRequest -Uri "$CONSUMER_URL/api/consumer/monitoring/statistics?hours=1" -Method GET -TimeoutSec 30
        $stats = $statsResponse.Content | ConvertFrom-Json
        
        Write-ColoredLog "SUCCESS" "📊 FINAL RESULTS:"
        Write-ColoredLog "SUCCESS" "  Total Messages Processed: $($stats.total_messages)"
        Write-ColoredLog "SUCCESS" "  Successful: $($stats.successful_messages)"
        Write-ColoredLog "SUCCESS" "  Failed: $($stats.failed_messages)"
        
        if ($stats.total_messages -gt 0) {
            $successRate = [Math]::Round(($stats.successful_messages * 100 / $stats.total_messages), 2)
            Write-ColoredLog "SUCCESS" "  Success Rate: ${successRate}%"
        }
        
        Write-ColoredLog "SUCCESS" "  Average Processing Time: $($stats.average_processing_time_ms)ms"
    } catch {
        Write-ColoredLog "ERROR" "Could not retrieve final statistics: $($_.Exception.Message)"
    }
    
    # Check Elasticsearch document count
    try {
        $esResponse = Invoke-WebRequest -Uri "$ELASTICSEARCH_URL/kbnt-consumption-logs-*/_count" -Method GET -TimeoutSec 30
        $esCount = ($esResponse.Content | ConvertFrom-Json).count
        Write-ColoredLog "SUCCESS" "  Documents in Elasticsearch: $esCount"
    } catch {
        Write-ColoredLog "WARNING" "Could not retrieve Elasticsearch count: $($_.Exception.Message)"
    }
}

function Open-KibanaDashboard {
    Write-ColoredLog "INFO" "Opening Kibana dashboard in default browser..."
    Start-Process "$KIBANA_URL/app/dashboards"
    
    Write-ColoredLog "INFO" "If the dashboard doesn't open automatically, visit:"
    Write-ColoredLog "INFO" "  $KIBANA_URL/app/dashboards"
}

function Show-Help {
    Write-Host @"
KBNT Traffic Test and Kibana Dashboard Automation

USAGE:
    .\run-traffic-test.ps1 [OPTIONS]

OPTIONS:
    -TotalMessages <int>        Number of messages to send (default: 500)
    -ConcurrentThreads <int>    Number of concurrent threads (default: 10)
    -BatchSize <int>            Messages per batch (default: 50)
    -DelayBetweenBatches <int>  Delay between batches in seconds (default: 2)
    -SkipTest                   Skip load test, only setup dashboard
    -OpenKibana                 Open Kibana dashboard in browser after test
    -Help                       Show this help message

EXAMPLES:
    .\run-traffic-test.ps1
    .\run-traffic-test.ps1 -TotalMessages 1000 -ConcurrentThreads 20
    .\run-traffic-test.ps1 -SkipTest -OpenKibana
    .\run-traffic-test.ps1 -TotalMessages 200 -OpenKibana

PREREQUISITES:
    - Docker and Docker Compose installed
    - PowerShell 5.1 or higher
    - All KBNT services running
    - Elasticsearch stack running

"@ -ForegroundColor Cyan
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-ColoredLog "HEADER" "KBNT TRAFFIC TEST WITH KIBANA DASHBOARD - POWERSHELL"
Write-ColoredLog "INFO" "Starting comprehensive traffic test and dashboard setup..."

# Check if services are healthy
if (-not (Test-ServiceHealth)) {
    Write-ColoredLog "ERROR" "Service health check failed. Starting Elasticsearch stack..."
    if (-not (Start-ElasticsearchStack)) {
        Write-ColoredLog "ERROR" "Failed to start required services. Please check your environment."
        exit 1
    }
    
    # Recheck services after starting stack
    if (-not (Test-ServiceHealth)) {
        Write-ColoredLog "ERROR" "Services are still not healthy after stack startup."
        exit 1
    }
}

# Setup Kibana dashboard
if (-not (Setup-KibanaDashboard)) {
    Write-ColoredLog "WARNING" "Dashboard setup failed, but continuing with test..."
}

# Run load test (unless skipped)
if (-not $SkipTest) {
    $testResults = Start-LoadTest
    
    # Analyze results
    Show-TestResults
} else {
    Write-ColoredLog "INFO" "Skipping load test as requested"
}

# Final instructions and dashboard access
Write-ColoredLog "HEADER" "TEST COMPLETED - KIBANA DASHBOARD ACCESS"
Write-ColoredLog "SUCCESS" "🎉 Traffic test completed successfully!"
Write-ColoredLog "INFO" ""
Write-ColoredLog "INFO" "📊 Access your Kibana dashboard:"
Write-ColoredLog "INFO" "  URL: $KIBANA_URL/app/dashboards"
Write-ColoredLog "INFO" "  Data View: kbnt-consumption-logs-*"
Write-ColoredLog "INFO" "  Time Range: Last 1 hour"
Write-ColoredLog "INFO" ""
Write-ColoredLog "INFO" "🔍 Useful Kibana searches:"
Write-ColoredLog "INFO" "  All test messages: metadata.test_run:true"
Write-ColoredLog "INFO" "  Failed messages: status:FAILED"
Write-ColoredLog "INFO" "  High priority: priority:HIGH"
Write-ColoredLog "INFO" "  Specific product: product_id:SMARTPHONE*"
Write-ColoredLog "INFO" ""
Write-ColoredLog "INFO" "📈 Available visualizations:"
Write-ColoredLog "INFO" "  1. Message volume over time"
Write-ColoredLog "INFO" "  2. Status distribution"
Write-ColoredLog "INFO" "  3. Processing time histogram"
Write-ColoredLog "INFO" "  4. Priority distribution"
Write-ColoredLog "INFO" "  5. Recent messages table"
Write-ColoredLog "INFO" "  6. Key metrics (total, avg time, success rate)"

if ($OpenKibana) {
    Open-KibanaDashboard
}

Write-ColoredLog "SUCCESS" "Open $KIBANA_URL to view real-time traffic data!"
