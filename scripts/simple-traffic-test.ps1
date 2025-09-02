# KBNT Simple Traffic Test Script for Windows
# Simplified PowerShell script to test traffic and monitor results

param(
    [int]$TotalMessages = 100,
    [int]$BatchSize = 10
)

# Configuration
$PRODUCER_URL = "http://localhost:8080"
$CONSUMER_URL = "http://localhost:8081"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $(if($Level -eq "ERROR"){"Red"} elseif($Level -eq "SUCCESS"){"Green"} else{"Cyan"})
}

function Test-Services {
    Write-Log "Checking service availability..." "INFO"
    
    try {
        $producerHealth = Invoke-WebRequest -Uri "$PRODUCER_URL/actuator/health" -TimeoutSec 10
        Write-Log "Producer Service: OK" "SUCCESS"
    } catch {
        Write-Log "Producer Service: FAILED - $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    try {
        $consumerHealth = Invoke-WebRequest -Uri "$CONSUMER_URL/api/consumer/actuator/health" -TimeoutSec 10
        Write-Log "Consumer Service: OK" "SUCCESS"
    } catch {
        Write-Log "Consumer Service: FAILED - $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    return $true
}

function Send-TestMessage {
    param(
        [string]$CorrelationId,
        [string]$ProductId,
        [decimal]$Price,
        [string]$Operation,
        [int]$Quantity
    )
    
    $payload = @{
        correlationId = $CorrelationId
        productId = $ProductId
        quantity = $Quantity
        price = $Price
        operation = $Operation
        priority = "HIGH"
        exchange = "NYSE"
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        metadata = @{
            test_run = $true
            source = "simple-traffic-test"
        }
    } | ConvertTo-Json -Depth 3
    
    $headers = @{
        "Content-Type" = "application/json"
        "X-Correlation-ID" = $CorrelationId
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$PRODUCER_URL/api/stock/update" -Method POST -Body $payload -Headers $headers -TimeoutSec 30
        return @{ Success = $true; Status = $response.StatusCode }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Start-TrafficTest {
    Write-Log "Starting traffic test with $TotalMessages messages..." "INFO"
    
    $products = @(
        @{ Id = "SMARTPHONE-TEST"; Price = 599.99 },
        @{ Id = "TABLET-TEST"; Price = 399.99 },
        @{ Id = "NOTEBOOK-TEST"; Price = 1299.99 }
    )
    
    $operations = @("INCREASE", "DECREASE", "SET")
    
    $successCount = 0
    $failCount = 0
    $startTime = Get-Date
    
    for ($i = 1; $i -le $TotalMessages; $i++) {
        $correlationId = "TRAFFIC-TEST-$(Get-Date -UFormat %s)-$i"
        $product = $products | Get-Random
        $operation = $operations | Get-Random
        $quantity = Get-Random -Minimum 100 -Maximum 1000
        
        $result = Send-TestMessage -CorrelationId $correlationId -ProductId $product.Id -Price $product.Price -Operation $operation -Quantity $quantity
        
        if ($result.Success) {
            $successCount++
            Write-Progress -Activity "Sending Messages" -Status "Success: $successCount, Failed: $failCount" -PercentComplete (($i / $TotalMessages) * 100)
        } else {
            $failCount++
            Write-Log "Message $i failed: $($result.Error)" "ERROR"
        }
        
        # Small delay to avoid overwhelming
        Start-Sleep -Milliseconds 200
        
        # Show progress every 10 messages
        if ($i % 10 -eq 0) {
            Write-Log "Sent $i/$TotalMessages messages (Success: $successCount, Failed: $failCount)" "INFO"
        }
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    $throughput = [Math]::Round($TotalMessages / $duration, 2)
    
    Write-Log "Test completed!" "SUCCESS"
    Write-Log "Duration: $duration seconds" "INFO"
    Write-Log "Total: $TotalMessages, Success: $successCount, Failed: $failCount" "INFO"
    Write-Log "Throughput: $throughput messages/second" "INFO"
    
    return @{
        Success = $successCount
        Failed = $failCount
        Duration = $duration
        Throughput = $throughput
    }
}

function Get-ConsumerStatistics {
    Write-Log "Waiting for message processing..." "INFO"
    Start-Sleep -Seconds 30
    
    try {
        $response = Invoke-WebRequest -Uri "$CONSUMER_URL/api/consumer/monitoring/statistics?hours=1" -TimeoutSec 30
        $stats = $response.Content | ConvertFrom-Json
        
        Write-Log "=== CONSUMER STATISTICS ===" "SUCCESS"
        Write-Log "Total Messages: $($stats.total_messages)" "SUCCESS"
        Write-Log "Successful: $($stats.successful_messages)" "SUCCESS"
        Write-Log "Failed: $($stats.failed_messages)" "SUCCESS"
        Write-Log "Average Processing Time: $($stats.average_processing_time_ms)ms" "SUCCESS"
        
        if ($stats.total_messages -gt 0) {
            $successRate = [Math]::Round(($stats.successful_messages * 100 / $stats.total_messages), 2)
            Write-Log "Success Rate: $successRate%" "SUCCESS"
        }
        
    } catch {
        Write-Log "Could not retrieve consumer statistics: $($_.Exception.Message)" "ERROR"
    }
}

# Main execution
Write-Log "=== KBNT SIMPLE TRAFFIC TEST ===" "INFO"

if (-not (Test-Services)) {
    Write-Log "Service health check failed. Please ensure Producer and Consumer services are running." "ERROR"
    exit 1
}

$testResults = Start-TrafficTest

Get-ConsumerStatistics

Write-Log "=== TEST COMPLETED ===" "SUCCESS"
Write-Log "Check your monitoring dashboards for detailed traffic analysis" "INFO"

# Try to open monitoring URLs
try {
    Write-Log "Opening monitoring endpoints..." "INFO"
    Start-Process "http://localhost:8080/actuator/metrics"
    Start-Process "http://localhost:8081/api/consumer/monitoring/statistics"
} catch {
    Write-Log "Could not open browser. Manual URLs:" "INFO"
    Write-Log "Producer Metrics: http://localhost:8080/actuator/metrics" "INFO"
    Write-Log "Consumer Stats: http://localhost:8081/api/consumer/monitoring/statistics" "INFO"
}
