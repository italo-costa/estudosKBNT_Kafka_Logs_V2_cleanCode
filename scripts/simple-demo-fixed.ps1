# KBNT Simple Demo - Fixed Version
# Simple traffic simulation with HTTP endpoints

param(
    [int]$Messages = 20
)

function Write-Status {
    param([string]$Text, [string]$Type = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $color = switch($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host "[$time] [$Type] $Text" -ForegroundColor $color
}

function Send-TestMessage {
    param(
        [string]$Url,
        [string]$CorrelationId,
        [string]$ProductId,
        [int]$Quantity,
        [decimal]$Price,
        [string]$Operation
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
            source = "simple-demo"
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method POST -Body $payload -ContentType "application/json" -TimeoutSec 10
        return @{ Success = $true; Data = $response }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-SimpleWorkflow {
    Write-Status "=== KBNT SIMPLE DEMO TRAFFIC TEST ===" "INFO"
    Write-Status "Testing with $Messages messages" "INFO"
    
    # Test data
    $products = @(
        @{ Id = "DEMO-SMARTPHONE-001"; Price = 599.99 },
        @{ Id = "DEMO-TABLET-002"; Price = 399.99 },
        @{ Id = "DEMO-LAPTOP-003"; Price = 1299.99 },
        @{ Id = "DEMO-WATCH-004"; Price = 299.99 },
        @{ Id = "DEMO-HEADPHONES-005"; Price = 149.99 }
    )
    
    $operations = @("INCREASE", "DECREASE", "SET", "SYNC")
    
    $results = @()
    $successCount = 0
    $failCount = 0
    
    # Check if we have a local service running
    $testUrls = @(
        "http://localhost:8080/api/stock/update",
        "http://localhost:8081/api/consumer/stock/update",
        "http://localhost:9090/api/stock/update"
    )
    
    $workingUrl = $null
    foreach ($url in $testUrls) {
        try {
            $healthCheck = Invoke-RestMethod -Uri ($url -replace "/api/stock/update", "/health") -Method GET -TimeoutSec 5
            $workingUrl = $url
            Write-Status "Found working service at: $url" "SUCCESS"
            break
        } catch {
            # Service not available at this URL
        }
    }
    
    if (-not $workingUrl) {
        Write-Status "No service found on standard ports. Creating mock responses..." "WARNING"
        
        # Simulate without actual service
        for ($i = 1; $i -le $Messages; $i++) {
            $correlationId = "DEMO-$(Get-Date -UFormat %s)-$i"
            $product = $products | Get-Random
            $operation = $operations | Get-Random
            $quantity = Get-Random -Minimum 100 -Maximum 1000
            
            # Simulate processing
            $processingTime = Get-Random -Minimum 50 -Maximum 200
            Start-Sleep -Milliseconds 100
            
            $mockResult = @{
                CorrelationId = $correlationId
                ProductId = $product.Id
                Operation = $operation
                Quantity = $quantity
                Price = $product.Price
                ProcessingTime = $processingTime
                Status = if ((Get-Random) % 10 -gt 0) { "SUCCESS" } else { "FAILED" }
                Timestamp = (Get-Date)
            }
            
            $results += $mockResult
            
            if ($mockResult.Status -eq "SUCCESS") {
                $successCount++
            } else {
                $failCount++
            }
            
            Write-Progress -Activity "Processing Messages" -Status "Message $i of $Messages" -PercentComplete (($i / $Messages) * 100)
            
            if ($i % 5 -eq 0) {
                Write-Status "Processed $i/$Messages messages (Success: $successCount, Failed: $failCount)" "INFO"
            }
        }
    } else {
        # Send to actual service
        Write-Status "Sending messages to: $workingUrl" "INFO"
        
        for ($i = 1; $i -le $Messages; $i++) {
            $correlationId = "DEMO-$(Get-Date -UFormat %s)-$i"
            $product = $products | Get-Random
            $operation = $operations | Get-Random
            $quantity = Get-Random -Minimum 100 -Maximum 1000
            
            $result = Send-TestMessage -Url $workingUrl -CorrelationId $correlationId -ProductId $product.Id -Quantity $quantity -Price $product.Price -Operation $operation
            
            if ($result.Success) {
                $successCount++
                Write-Status "✓ Message $i sent: $correlationId" "SUCCESS"
            } else {
                $failCount++
                Write-Status "✗ Message $i failed: $($result.Error)" "ERROR"
            }
            
            Write-Progress -Activity "Sending Messages" -Status "Message $i of $Messages" -PercentComplete (($i / $Messages) * 100)
            
            Start-Sleep -Milliseconds 200
        }
    }
    
    # Show results
    Write-Status "=== DEMO RESULTS ===" "SUCCESS"
    Write-Status "Total Messages: $Messages" "INFO"
    Write-Status "Successful: $successCount" "SUCCESS"
    Write-Status "Failed: $failCount" "$(if ($failCount -gt 0) { 'WARNING' } else { 'SUCCESS' })"
    
    if ($Messages -gt 0) {
        $successRate = [Math]::Round(($successCount * 100 / $Messages), 2)
        Write-Status "Success Rate: $successRate%" "SUCCESS"
    }
    
    if ($results.Count -gt 0) {
        $avgProcessingTime = ($results | Measure-Object -Property ProcessingTime -Average).Average
        Write-Status "Average Processing Time: $([Math]::Round($avgProcessingTime, 2))ms" "INFO"
    }
    
    # Show sample results
    if ($results.Count -gt 0) {
        Write-Status "Sample Results:" "INFO"
        $results | Select-Object -First 5 | ForEach-Object {
            Write-Status "  $($_.CorrelationId): $($_.ProductId) - $($_.Status) ($($_.ProcessingTime)ms)" "INFO"
        }
    }
    
    return @{
        Total = $Messages
        Success = $successCount
        Failed = $failCount
        Results = $results
    }
}

# Execute the test
try {
    $testResults = Test-SimpleWorkflow
    Write-Status "Demo completed successfully!" "SUCCESS"
    exit 0
} catch {
    Write-Status "Demo failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
