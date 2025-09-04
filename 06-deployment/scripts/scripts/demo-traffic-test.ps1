# KBNT Simple Demo - Traffic Test Without External Dependencies
# Demonstrates the message flow using simple HTTP endpoints and in-memory processing

param(
    [int]$TotalMessages = 20,
    [switch]$Verbose
)

# Configuration
$DEMO_PORT = 9090

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "HEADER" { "Magenta" }
        default { "Cyan" }
    }
    
    if ($Level -eq "HEADER") {
        Write-Host ""
        Write-Host "=== $Message ===" -ForegroundColor $color
    } else {
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

function Start-DemoServer {
    Write-Log "Starting Demo HTTP Server..." "INFO"
    
    # Simple PowerShell HTTP server for demonstration
    $script = {
        param($Port)
        
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://localhost:$Port/")
        $listener.Start()
        
        Write-Host "Demo server listening on port $Port..."
        
        $messageCount = 0
        $processedMessages = @()
        
        while ($listener.IsListening) {
            try {
                $context = $listener.GetContext()
                $request = $context.Request
                $response = $context.Response
                
                $responseText = ""
                $statusCode = 200
                
                switch ($request.Url.AbsolutePath) {
                    "/health" {
                        $responseText = '{"status":"UP","service":"KBNT-Demo","timestamp":"' + (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ") + '"}'
                        $response.ContentType = "application/json"
                    }
                    
                    "/api/stock/update" {
                        if ($request.HttpMethod -eq "POST") {
                            $reader = [System.IO.StreamReader]::new($request.InputStream)
                            $body = $reader.ReadToEnd()
                            $reader.Close()
                            
                            try {
                                $message = $body | ConvertFrom-Json
                                $messageCount++
                                
                                $processedMessage = @{
                                    id = $messageCount
                                    correlation_id = $message.correlationId
                                    product_id = $message.productId
                                    operation = $message.operation
                                    quantity = $message.quantity
                                    price = $message.price
                                    processed_at = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
                                    processing_time_ms = (Get-Random -Minimum 50 -Maximum 200)
                                    status = "SUCCESS"
                                }
                                
                                $processedMessages += $processedMessage
                                
                                $responseText = @{
                                    message = "Stock update processed successfully"
                                    correlation_id = $message.correlationId
                                    product_id = $message.productId
                                    status = "SUCCESS"
                                    processing_time_ms = $processedMessage.processing_time_ms
                                } | ConvertTo-Json
                                
                                Write-Host "Processed: $($message.correlationId) - $($message.productId) - $($message.operation)" -ForegroundColor Green
                                
                            } catch {
                                $statusCode = 400
                                $responseText = '{"error":"Invalid JSON payload","status":"FAILED"}'
                            }
                            
                            $response.ContentType = "application/json"
                        } else {
                            $statusCode = 405
                            $responseText = '{"error":"Method not allowed"}'
                        }
                    }
                    
                    "/api/stats" {
                        $stats = @{
                            total_messages = $messageCount
                            successful_messages = $processedMessages.Count
                            failed_messages = 0
                            average_processing_time_ms = if ($processedMessages.Count -gt 0) { 
                                ($processedMessages | Measure-Object -Property processing_time_ms -Average).Average 
                            } else { 0 }
                            last_processed = if ($processedMessages.Count -gt 0) { 
                                $processedMessages[-1].processed_at 
                            } else { $null }
                            uptime_seconds = ((Get-Date) - $script:startTime).TotalSeconds
                        }
                        
                        $responseText = $stats | ConvertTo-Json -Depth 3
                        $response.ContentType = "application/json"
                    }
                    
                    "/api/messages" {
                        $responseText = @{
                            messages = $processedMessages
                            count = $processedMessages.Count
                        } | ConvertTo-Json -Depth 3
                        $response.ContentType = "application/json"
                    }
                    
                    default {
                        $statusCode = 404
                        $responseText = '{"error":"Endpoint not found"}'
                    }
                }
                
                $response.StatusCode = $statusCode
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.Close()
                
            } catch {
                Write-Host "Server error: $($_.Exception.Message)" -ForegroundColor Red
                break
            }
        }
        
        $listener.Stop()
    }
    
    $script:startTime = Get-Date
    $job = Start-Job -ScriptBlock $script -ArgumentList $DEMO_PORT
    
    # Wait for server to start
    Start-Sleep -Seconds 3
    
    # Test server
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$DEMO_PORT/health" -TimeoutSec 5
        Write-Log "Demo server started successfully on port $DEMO_PORT" "SUCCESS"
        return $job
    } catch {
        Write-Log "Failed to start demo server: $($_.Exception.Message)" "ERROR"
        Stop-Job -Job $job -Force
        Remove-Job -Job $job -Force
        return $null
    }
}

function Send-DemoMessage {
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
        exchange = "DEMO"
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        metadata = @{
            test_run = $true
            source = "demo-traffic-test"
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$DEMO_PORT/api/stock/update" -Method POST -Body $payload -ContentType "application/json" -TimeoutSec 10
        
        if ($response.StatusCode -eq 200) {
            $result = $response.Content | ConvertFrom-Json
            return @{ Success = $true; Result = $result }
        } else {
            return @{ Success = $false; Error = "HTTP $($response.StatusCode)" }
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Start-DemoTrafficTest {
    Write-Log "Starting Demo Traffic Test" "HEADER"
    Write-Log "Sending $TotalMessages messages to demo server..." "INFO"
    
    $products = @(
        @{ Id = "SMARTPHONE-DEMO-001"; Price = 599.99 },
        @{ Id = "TABLET-DEMO-002"; Price = 399.99 },
        @{ Id = "NOTEBOOK-DEMO-003"; Price = 1299.99 },
        @{ Id = "HEADPHONE-DEMO-004"; Price = 149.99 }
    )
    
    $operations = @("INCREASE", "DECREASE", "SET")
    
    $successCount = 0
    $failCount = 0
    $startTime = Get-Date
    
    for ($i = 1; $i -le $TotalMessages; $i++) {
        $correlationId = "DEMO-$(Get-Date -UFormat %s)-$('{0:D3}' -f $i)"
        $product = $products | Get-Random
        $operation = $operations | Get-Random
        $quantity = Get-Random -Minimum 10 -Maximum 100
        
        $result = Send-DemoMessage -CorrelationId $correlationId -ProductId $product.Id -Price $product.Price -Operation $operation -Quantity $quantity
        
        if ($result.Success) {
            $successCount++
            if ($Verbose) {
                Write-Log "✓ $correlationId - $($product.Id) - $operation" "SUCCESS"
            }
        } else {
            $failCount++
            Write-Log "✗ $correlationId - $($result.Error)" "ERROR"
        }
        
        # Progress indicator
        $progress = [Math]::Round(($i / $TotalMessages) * 100)
        Write-Progress -Activity "Sending Messages" -Status "$i/$TotalMessages" -PercentComplete $progress
        
        # Small delay between messages
        Start-Sleep -Milliseconds 100
    }
    
    Write-Progress -Activity "Sending Messages" -Completed
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    $throughput = [Math]::Round($TotalMessages / $duration, 2)
    
    Write-Log "Demo Traffic Test Completed" "HEADER"
    Write-Log "Duration: $([Math]::Round($duration, 2)) seconds" "SUCCESS"
    Write-Log "Total: $TotalMessages | Success: $successCount | Failed: $failCount" "SUCCESS"
    Write-Log "Throughput: $throughput messages/second" "SUCCESS"
    
    return @{
        Total = $TotalMessages
        Success = $successCount
        Failed = $failCount
        Duration = $duration
        Throughput = $throughput
    }
}

function Show-DemoResults {
    Write-Log "Fetching Demo Results" "HEADER"
    
    Start-Sleep -Seconds 2  # Give server time to process
    
    try {
        # Get statistics
        $statsResponse = Invoke-WebRequest -Uri "http://localhost:$DEMO_PORT/api/stats" -TimeoutSec 10
        $stats = $statsResponse.Content | ConvertFrom-Json
        
        Write-Log "SERVER STATISTICS" "HEADER"
        Write-Log "Total Messages Processed: $($stats.total_messages)" "SUCCESS"
        Write-Log "Successful Messages: $($stats.successful_messages)" "SUCCESS"
        Write-Log "Failed Messages: $($stats.failed_messages)" "SUCCESS"
        Write-Log "Average Processing Time: $([Math]::Round($stats.average_processing_time_ms, 2))ms" "SUCCESS"
        Write-Log "Server Uptime: $([Math]::Round($stats.uptime_seconds, 2)) seconds" "SUCCESS"
        
        # Get recent messages
        $messagesResponse = Invoke-WebRequest -Uri "http://localhost:$DEMO_PORT/api/messages" -TimeoutSec 10
        $messagesData = $messagesResponse.Content | ConvertFrom-Json
        
        if ($messagesData.messages.Count -gt 0) {
            Write-Log "RECENT MESSAGES SAMPLE" "HEADER"
            $sampleCount = [Math]::Min(5, $messagesData.messages.Count)
            $lastMessages = $messagesData.messages | Select-Object -Last $sampleCount
            
            foreach ($msg in $lastMessages) {
                Write-Log "• $($msg.correlation_id) | $($msg.product_id) | $($msg.operation) | $($msg.processing_time_ms)ms" "INFO"
            }
        }
        
    } catch {
        Write-Log "Could not fetch demo results: $($_.Exception.Message)" "WARNING"
    }
}

function Open-DemoDashboard {
    Write-Log "Demo Dashboard URLs" "HEADER"
    Write-Log "Health Check: http://localhost:$DEMO_PORT/health" "INFO"
    Write-Log "Statistics: http://localhost:$DEMO_PORT/api/stats" "INFO"
    Write-Log "All Messages: http://localhost:$DEMO_PORT/api/messages" "INFO"
    
    Write-Log "Opening demo dashboard..." "INFO"
    try {
        Start-Process "http://localhost:$DEMO_PORT/api/stats"
        Write-Log "Dashboard opened in browser" "SUCCESS"
    } catch {
        Write-Log "Please manually open: http://localhost:$DEMO_PORT/api/stats" "WARNING"
    }
}

# Main execution
Write-Log "KBNT DEMO TRAFFIC TEST" "HEADER"
Write-Log "This demo simulates the KBNT workflow without external dependencies" "INFO"

# Start demo server
$serverJob = Start-DemoServer

if ($serverJob -eq $null) {
    Write-Log "Failed to start demo server. Exiting." "ERROR"
    exit 1
}

try {
    # Run traffic test
    $testResults = Start-DemoTrafficTest
    
    # Show results
    Show-DemoResults
    
    # Open dashboard
    Open-DemoDashboard
    
    Write-Log "DEMO COMPLETED SUCCESSFULLY" "HEADER"
    Write-Log "The demo server is still running for inspection" "SUCCESS"
    Write-Log "Press Ctrl+C to stop the demo server when done" "INFO"
    
    # Keep server running
    Write-Log "Demo server running... (Press Ctrl+C to stop)" "INFO"
    Wait-Job -Job $serverJob
    
} finally {
    # Cleanup
    if ($serverJob) {
        Write-Log "Stopping demo server..." "INFO"
        Stop-Job -Job $serverJob -Force
        Remove-Job -Job $serverJob -Force
    }
}
