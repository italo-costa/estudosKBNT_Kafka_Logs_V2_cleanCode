# KBNT Traffic Test and Monitoring Dashboard Script
# Tests message traffic between kbnt-log-service (Producer) and kbnt-stock-consumer-service

param(
    [int]$TotalMessages = 100,
    [int]$BatchSize = 10,
    [switch]$StartServices,
    [switch]$OnlyTest,
    [switch]$Help
)

# Configuration
$LOG_SERVICE_URL = "http://localhost:8080"      # kbnt-log-service (Producer)
$CONSUMER_SERVICE_URL = "http://localhost:8081" # kbnt-stock-consumer-service

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "HEADER" { "Magenta" }
        default { "Cyan" }
    }
    
    if ($Level -eq "HEADER") {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor $color
        Write-Host $Message -ForegroundColor $color
        Write-Host "========================================" -ForegroundColor $color
    } else {
        Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $color
    }
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    # Check Java
    try {
        $javaVersion = java -version 2>&1
        Write-Log "Java is available" "SUCCESS"
    } catch {
        Write-Log "Java is not available. Please install Java 17+" "ERROR"
        return $false
    }
    
    # Check Maven
    try {
        $mavenVersion = mvn -version 2>&1
        Write-Log "Maven is available" "SUCCESS"
    } catch {
        Write-Log "Maven is not available. Please install Maven" "ERROR"
        return $false
    }
    
    return $true
}

function Start-LogService {
    Write-Log "Starting KBNT Log Service (Producer)..." "INFO"
    
    $servicePath = "c:\workspace\estudosKBNT_Kafka_Logs\microservices\kbnt-log-service"
    
    if (-not (Test-Path $servicePath)) {
        Write-Log "Log service path not found: $servicePath" "ERROR"
        return $false
    }
    
    try {
        Push-Location $servicePath
        
        Write-Log "Building Log Service..." "INFO"
        $buildResult = mvn clean package -DskipTests 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Log Service built successfully" "SUCCESS"
            
            # Find the JAR file
            $jarFiles = Get-ChildItem -Path "target" -Filter "*.jar" | Where-Object { $_.Name -notlike "*-sources.jar" -and $_.Name -notlike "*-javadoc.jar" }
            
            if ($jarFiles.Count -gt 0) {
                $jarFile = $jarFiles[0].FullName
                Write-Log "Starting Log Service: $jarFile" "INFO"
                
                # Start the service in a new process
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = "java"
                $processInfo.Arguments = "-jar `"$jarFile`" --server.port=8080"
                $processInfo.WorkingDirectory = $servicePath
                $processInfo.UseShellExecute = $false
                $processInfo.CreateNoWindow = $false
                
                $process = [System.Diagnostics.Process]::Start($processInfo)
                Write-Log "Log Service started with PID: $($process.Id)" "SUCCESS"
                
                return $true
            } else {
                Write-Log "No JAR file found in target directory" "ERROR"
                return $false
            }
        } else {
            Write-Log "Failed to build Log Service" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error starting Log Service: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        Pop-Location
    }
}

function Start-ConsumerService {
    Write-Log "Starting KBNT Consumer Service..." "INFO"
    
    $servicePath = "c:\workspace\estudosKBNT_Kafka_Logs\microservices\kbnt-stock-consumer-service"
    
    if (-not (Test-Path $servicePath)) {
        Write-Log "Consumer service path not found: $servicePath" "ERROR"
        return $false
    }
    
    try {
        Push-Location $servicePath
        
        Write-Log "Building Consumer Service..." "INFO"
        $buildResult = mvn clean package -DskipTests 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Consumer Service built successfully" "SUCCESS"
            
            # Find the JAR file
            $jarFiles = Get-ChildItem -Path "target" -Filter "*.jar" | Where-Object { $_.Name -notlike "*-sources.jar" -and $_.Name -notlike "*-javadoc.jar" }
            
            if ($jarFiles.Count -gt 0) {
                $jarFile = $jarFiles[0].FullName
                Write-Log "Starting Consumer Service: $jarFile" "INFO"
                
                # Start the service in a new process
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = "java"
                $processInfo.Arguments = "-jar `"$jarFile`" --server.port=8081"
                $processInfo.WorkingDirectory = $servicePath
                $processInfo.UseShellExecute = $false
                $processInfo.CreateNoWindow = $false
                
                $process = [System.Diagnostics.Process]::Start($processInfo)
                Write-Log "Consumer Service started with PID: $($process.Id)" "SUCCESS"
                
                return $true
            } else {
                Write-Log "No JAR file found in target directory" "ERROR"
                return $false
            }
        } else {
            Write-Log "Failed to build Consumer Service" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error starting Consumer Service: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        Pop-Location
    }
}

function Wait-ForServices {
    Write-Log "Waiting for services to start..." "INFO"
    
    $maxWait = 120  # 2 minutes
    $checkInterval = 10
    $elapsed = 0
    
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        
        Write-Log "Checking services (${elapsed}s elapsed)..." "INFO"
        
        # Check Log Service
        try {
            $logHealth = Invoke-WebRequest -Uri "$LOG_SERVICE_URL/actuator/health" -TimeoutSec 5
            $logHealthy = $logHealth.StatusCode -eq 200
            if ($logHealthy) { Write-Log "Log Service: Healthy" "SUCCESS" }
        } catch {
            $logHealthy = $false
            Write-Log "Log Service: Not ready" "WARNING"
        }
        
        # Check Consumer Service
        try {
            $consumerHealth = Invoke-WebRequest -Uri "$CONSUMER_SERVICE_URL/actuator/health" -TimeoutSec 5
            $consumerHealthy = $consumerHealth.StatusCode -eq 200
            if ($consumerHealthy) { Write-Log "Consumer Service: Healthy" "SUCCESS" }
        } catch {
            $consumerHealthy = $false
            Write-Log "Consumer Service: Not ready" "WARNING"
        }
        
        if ($logHealthy -and $consumerHealthy) {
            Write-Log "All services are healthy!" "SUCCESS"
            return $true
        }
    }
    
    Write-Log "Timeout waiting for services" "ERROR"
    return $false
}

function Send-StockMessage {
    param(
        [string]$CorrelationId,
        [string]$ProductId,
        [decimal]$Price,
        [string]$Operation,
        [int]$Quantity,
        [string]$Priority = "HIGH"
    )
    
    $payload = @{
        correlationId = $CorrelationId
        productId = $ProductId
        quantity = $Quantity
        price = $Price
        operation = $Operation
        priority = $Priority
        exchange = "NYSE"
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        metadata = @{
            test_run = $true
            source = "traffic-test-powershell"
            batch_id = "BATCH-$(Get-Date -UFormat %s)"
        }
    } | ConvertTo-Json -Depth 3
    
    $headers = @{
        "Content-Type" = "application/json"
        "X-Correlation-ID" = $CorrelationId
        "X-Source" = "traffic-test"
    }
    
    try {
        # Try the stock update endpoint
        $response = Invoke-WebRequest -Uri "$LOG_SERVICE_URL/api/stock/update" -Method POST -Body $payload -Headers $headers -TimeoutSec 30
        return @{ Success = $true; StatusCode = $response.StatusCode; CorrelationId = $CorrelationId }
    } catch {
        try {
            # Try alternative endpoint if the first fails
            $response = Invoke-WebRequest -Uri "$LOG_SERVICE_URL/api/log/stock" -Method POST -Body $payload -Headers $headers -TimeoutSec 30
            return @{ Success = $true; StatusCode = $response.StatusCode; CorrelationId = $CorrelationId }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message; CorrelationId = $CorrelationId }
        }
    }
}

function Start-TrafficTest {
    Write-Log "STARTING TRAFFIC TEST" "HEADER"
    Write-Log "Test Configuration:" "INFO"
    Write-Log "  Total Messages: $TotalMessages" "INFO"
    Write-Log "  Batch Size: $BatchSize" "INFO"
    Write-Log "  Log Service URL: $LOG_SERVICE_URL" "INFO"
    Write-Log "  Consumer Service URL: $CONSUMER_SERVICE_URL" "INFO"
    
    $products = @(
        @{ Id = "SMARTPHONE-TRAFFIC-001"; Price = 599.99 },
        @{ Id = "TABLET-TRAFFIC-002"; Price = 399.99 },
        @{ Id = "NOTEBOOK-TRAFFIC-003"; Price = 1299.99 },
        @{ Id = "HEADPHONE-TRAFFIC-004"; Price = 149.99 },
        @{ Id = "SMARTWATCH-TRAFFIC-005"; Price = 299.99 },
        @{ Id = "SPEAKER-TRAFFIC-006"; Price = 89.99 },
        @{ Id = "CAMERA-TRAFFIC-007"; Price = 799.99 },
        @{ Id = "MONITOR-TRAFFIC-008"; Price = 249.99 }
    )
    
    $operations = @("INCREASE", "DECREASE", "SET", "SYNC")
    $priorities = @("LOW", "NORMAL", "HIGH", "CRITICAL")
    
    $successCount = 0
    $failCount = 0
    $startTime = Get-Date
    
    for ($i = 1; $i -le $TotalMessages; $i++) {
        $correlationId = "TRAFFIC-TEST-$(Get-Date -UFormat %s)-$('{0:D4}' -f $i)"
        $product = $products | Get-Random
        $operation = $operations | Get-Random
        $priority = $priorities | Get-Random
        $quantity = Get-Random -Minimum 100 -Maximum 1000
        
        $result = Send-StockMessage -CorrelationId $correlationId -ProductId $product.Id -Price $product.Price -Operation $operation -Quantity $quantity -Priority $priority
        
        if ($result.Success) {
            $successCount++
            Write-Progress -Activity "Sending Messages" -Status "Success: $successCount, Failed: $failCount" -PercentComplete (($i / $TotalMessages) * 100)
        } else {
            $failCount++
            Write-Log "Message $i failed: $($result.Error)" "WARNING"
        }
        
        # Show progress every 10 messages
        if ($i % 10 -eq 0) {
            Write-Log "Progress: $i/$TotalMessages (Success: $successCount, Failed: $failCount)" "INFO"
        }
        
        # Small delay between messages
        Start-Sleep -Milliseconds 200
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    $throughput = if ($duration -gt 0) { [Math]::Round($TotalMessages / $duration, 2) } else { 0 }
    
    Write-Log "TRAFFIC TEST COMPLETED" "HEADER"
    Write-Log "Duration: $([Math]::Round($duration, 2)) seconds" "SUCCESS"
    Write-Log "Total Messages: $TotalMessages" "SUCCESS"
    Write-Log "Successful: $successCount" "SUCCESS"
    Write-Log "Failed: $failCount" "SUCCESS"
    Write-Log "Success Rate: $([Math]::Round($successCount * 100 / $TotalMessages, 2))%" "SUCCESS"
    Write-Log "Throughput: $throughput messages/second" "SUCCESS"
    
    return @{
        Total = $TotalMessages
        Success = $successCount
        Failed = $failCount
        Duration = $duration
        Throughput = $throughput
    }
}

function Get-MonitoringData {
    Write-Log "COLLECTING MONITORING DATA" "HEADER"
    
    # Wait for processing
    Write-Log "Waiting for message processing (60 seconds)..." "INFO"
    Start-Sleep -Seconds 60
    
    # Get Consumer Statistics
    try {
        Write-Log "Fetching consumer statistics..." "INFO"
        $statsResponse = Invoke-WebRequest -Uri "$CONSUMER_SERVICE_URL/api/consumer/monitoring/statistics?hours=1" -TimeoutSec 30
        $stats = $statsResponse.Content | ConvertFrom-Json
        
        Write-Log "CONSUMER STATISTICS" "HEADER"
        Write-Log "Total Messages Processed: $($stats.total_messages)" "SUCCESS"
        Write-Log "Successful Messages: $($stats.successful_messages)" "SUCCESS"
        Write-Log "Failed Messages: $($stats.failed_messages)" "SUCCESS"
        Write-Log "Average Processing Time: $($stats.average_processing_time_ms)ms" "SUCCESS"
        
        if ($stats.total_messages -gt 0) {
            $successRate = [Math]::Round(($stats.successful_messages * 100 / $stats.total_messages), 2)
            Write-Log "Consumer Success Rate: $successRate%" "SUCCESS"
        }
    } catch {
        Write-Log "Could not retrieve consumer statistics: $($_.Exception.Message)" "WARNING"
    }
    
    # Try to get producer metrics
    try {
        Write-Log "Fetching producer metrics..." "INFO"
        $metricsResponse = Invoke-WebRequest -Uri "$LOG_SERVICE_URL/actuator/metrics" -TimeoutSec 30
        Write-Log "Producer metrics available at: $LOG_SERVICE_URL/actuator/metrics" "SUCCESS"
    } catch {
        Write-Log "Could not retrieve producer metrics: $($_.Exception.Message)" "WARNING"
    }
}

function Show-Dashboard {
    Write-Log "MONITORING DASHBOARD" "HEADER"
    
    Write-Log "Service Endpoints:" "INFO"
    Write-Log "  Log Service (Producer): $LOG_SERVICE_URL" "INFO"
    Write-Log "    Health: $LOG_SERVICE_URL/actuator/health" "INFO"
    Write-Log "    Metrics: $LOG_SERVICE_URL/actuator/metrics" "INFO"
    Write-Log "" "INFO"
    Write-Log "  Consumer Service: $CONSUMER_SERVICE_URL" "INFO"
    Write-Log "    Health: $CONSUMER_SERVICE_URL/actuator/health" "INFO"
    Write-Log "    Statistics: $CONSUMER_SERVICE_URL/api/consumer/monitoring/statistics" "INFO"
    Write-Log "" "INFO"
    
    Write-Log "Opening monitoring endpoints..." "INFO"
    try {
        Start-Process "$LOG_SERVICE_URL/actuator/health"
        Start-Process "$CONSUMER_SERVICE_URL/api/consumer/monitoring/statistics"
    } catch {
        Write-Log "Could not open browser automatically. Please visit the URLs manually." "WARNING"
    }
}

function Show-Help {
    Write-Host @"
KBNT Traffic Test and Monitoring Script

This script tests message traffic between:
- kbnt-log-service (Producer) on port 8080
- kbnt-stock-consumer-service (Consumer) on port 8081

USAGE:
    .\traffic-test-complete.ps1 [OPTIONS]

OPTIONS:
    -TotalMessages <int>    Number of messages to send (default: 100)
    -BatchSize <int>        Messages per batch (default: 10)  
    -StartServices          Build and start services before testing
    -OnlyTest               Skip service startup, only run traffic test
    -Help                   Show this help

EXAMPLES:
    .\traffic-test-complete.ps1 -StartServices
    .\traffic-test-complete.ps1 -OnlyTest -TotalMessages 200
    .\traffic-test-complete.ps1 -TotalMessages 50

PREREQUISITES:
    - Java 17+ and Maven installed
    - KBNT microservices source code
    - Kafka running (for complete workflow)

"@ -ForegroundColor Cyan
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Log "KBNT TRAFFIC TEST AND DASHBOARD" "HEADER"

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Log "Prerequisites check failed. Please install required tools." "ERROR"
    exit 1
}

# Start services if requested
if ($StartServices -and -not $OnlyTest) {
    Write-Log "Starting services..." "INFO"
    
    $logStarted = Start-LogService
    Start-Sleep -Seconds 10  # Give log service time to start
    
    $consumerStarted = Start-ConsumerService
    
    if ($logStarted -and $consumerStarted) {
        if (-not (Wait-ForServices)) {
            Write-Log "Services failed to start properly" "ERROR"
            exit 1
        }
    } else {
        Write-Log "Failed to start one or more services" "ERROR"
        exit 1
    }
}

# Run traffic test
$testResults = Start-TrafficTest

# Collect monitoring data
Get-MonitoringData

# Show dashboard
Show-Dashboard

Write-Log "TRAFFIC TEST AND MONITORING COMPLETE" "HEADER"
Write-Log "Check the opened browser windows for real-time monitoring data" "SUCCESS"
