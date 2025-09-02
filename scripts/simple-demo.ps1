# Simple KBNT Demo - Traffic Test Simulation
# Creates a demo HTTP endpoint and sends test messages to simulate traffic

param(
    [int]$Messages = 20
)

$Port = 9090

function Write-Status {
    param([string]$Text, [string]$Type = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $color = if($Type -eq "SUCCESS") {"Green"} elseif($Type -eq "ERROR") {"Red"} else {"Cyan"}
    Write-Host "[$time] [$Type] $Text" -ForegroundColor $color
}

# Create simple demo server
function Start-DemoServer {
    Write-Status "Starting demo server on port $Port..." "INFO"
    
    $script = {
        param($ServerPort)
        
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$ServerPort/")
        $listener.Start()
        
        $messages = @()
        $totalReceived = 0
        
        Write-Host "Demo server listening on port $ServerPort"
        
        while ($listener.IsListening) {
            try {
                $context = $listener.GetContext()
                $request = $context.Request
                $response = $context.Response
                
                $responseJson = ""
                $statusCode = 200
                
                switch ($request.Url.AbsolutePath) {
                    "/health" {
                        $responseJson = '{"status":"UP","timestamp":"' + (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') + '"}'
                    }
                    
                    "/api/stock/update" {
                        if ($request.HttpMethod -eq "POST") {
                            $reader = New-Object System.IO.StreamReader($request.InputStream)
                            $body = $reader.ReadToEnd()
                            $reader.Close()
                            
                            try {
                                $data = $body | ConvertFrom-Json
                                $totalReceived++
                                
                                $processedMsg = @{
                                    id = $totalReceived
                                    correlation_id = $data.correlationId
                                    product_id = $data.productId
                                    operation = $data.operation
                                    quantity = $data.quantity
                                    price = $data.price
                                    processed_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
                                    processing_time_ms = (Get-Random -Min 50 -Max 200)
                                    status = "SUCCESS"
                                }
                                
                                $messages += $processedMsg
                                
                                $responseJson = @{
                                    message = "Processed successfully"
                                    correlation_id = $data.correlationId
                                    status = "SUCCESS"
                                    processing_time = $processedMsg.processing_time_ms
                                } | ConvertTo-Json
                                
                                Write-Host "Processed: $($data.correlationId) - $($data.productId)" -ForegroundColor Green
                            }
                            catch {
                                $statusCode = 400
                                $responseJson = '{"error":"Invalid data","status":"FAILED"}'
                            }
                        }
                        else {
                            $statusCode = 405
                            $responseJson = '{"error":"Method not allowed"}'
                        }
                    }
                    
                    "/api/stats" {
                        $avgTime = if ($messages.Count -gt 0) { 
                            ($messages | Measure-Object -Property processing_time_ms -Average).Average
                        } else { 0 }
                        
                        $stats = @{
                            total_messages = $totalReceived
                            successful_messages = $messages.Count
                            failed_messages = 0
                            average_processing_time_ms = $avgTime
                            uptime = "Demo Mode"
                        }
                        
                        $responseJson = $stats | ConvertTo-Json
                    }
                    
                    default {
                        $statusCode = 404
                        $responseJson = '{"error":"Not found"}'
                    }
                }
                
                $response.StatusCode = $statusCode
                $response.ContentType = "application/json"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.Close()
            }
            catch {
                Write-Host "Server error: $($_.Exception.Message)" -ForegroundColor Red
                break
            }
        }
        
        $listener.Stop()
    }
    
    $job = Start-Job -ScriptBlock $script -ArgumentList $Port
    Start-Sleep 3
    
    # Test if server is running
    try {
        Invoke-WebRequest -Uri "http://localhost:$Port/health" -TimeoutSec 5 | Out-Null
        Write-Status "Demo server started successfully" "SUCCESS"
        return $job
    }
    catch {
        Write-Status "Failed to start server" "ERROR"
        Stop-Job $job -Force
        Remove-Job $job -Force
        return $null
    }
}

# Send test messages
function Send-TestMessages {
    Write-Status "Sending $Messages test messages..." "INFO"
    
    $products = @(
        @{Id="PHONE-001"; Price=599.99},
        @{Id="TABLET-002"; Price=399.99},
        @{Id="LAPTOP-003"; Price=1299.99}
    )
    
    $operations = @("INCREASE", "DECREASE", "SET")
    
    $success = 0
    $failed = 0
    $startTime = Get-Date
    
    for ($i = 1; $i -le $Messages; $i++) {
        $product = $products | Get-Random
        $operation = $operations | Get-Random
        $correlationId = "DEMO-TEST-$i"
        
        $payload = @{
            correlationId = $correlationId
            productId = $product.Id
            quantity = (Get-Random -Min 10 -Max 100)
            price = $product.Price
            operation = $operation
            priority = "HIGH"
            timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        } | ConvertTo-Json
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port/api/stock/update" -Method POST -Body $payload -ContentType "application/json" -TimeoutSec 10
            
            if ($response.StatusCode -eq 200) {
                $success++
                Write-Progress -Activity "Sending Messages" -Status "$i/$Messages" -PercentComplete (($i/$Messages) * 100)
            }
            else {
                $failed++
            }
        }
        catch {
            $failed++
            Write-Status "Failed to send message $i" "ERROR"
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    Write-Progress -Activity "Sending Messages" -Completed
    
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    Write-Status "Test completed in $([Math]::Round($duration, 2)) seconds" "SUCCESS"
    Write-Status "Success: $success, Failed: $failed" "SUCCESS"
    Write-Status "Throughput: $([Math]::Round($Messages/$duration, 2)) messages/sec" "SUCCESS"
}

# Get results
function Show-Results {
    Write-Status "Fetching results..." "INFO"
    Start-Sleep 2
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port/api/stats" -TimeoutSec 10
        $stats = $response.Content | ConvertFrom-Json
        
        Write-Status "=== SERVER STATISTICS ===" "SUCCESS"
        Write-Status "Total Messages: $($stats.total_messages)" "SUCCESS"
        Write-Status "Successful: $($stats.successful_messages)" "SUCCESS"
        Write-Status "Failed: $($stats.failed_messages)" "SUCCESS"
        Write-Status "Avg Processing Time: $([Math]::Round($stats.average_processing_time_ms, 2))ms" "SUCCESS"
    }
    catch {
        Write-Status "Could not fetch stats" "ERROR"
    }
}

# Main execution
Write-Status "=== KBNT DEMO TRAFFIC TEST ===" "INFO"

$serverJob = Start-DemoServer

if ($serverJob) {
    try {
        Send-TestMessages
        Show-Results
        
        Write-Status "Demo completed! Server URLs:" "SUCCESS"
        Write-Status "Health: http://localhost:$Port/health" "INFO"
        Write-Status "Stats: http://localhost:$Port/api/stats" "INFO"
        
        # Open browser
        try {
            Start-Process "http://localhost:$Port/api/stats"
            Write-Status "Opened stats in browser" "SUCCESS"
        }
        catch {
            Write-Status "Please open http://localhost:$Port/api/stats manually" "INFO"
        }
        
        Write-Status "Press Enter to stop the demo server..." "INFO"
        Read-Host
    }
    finally {
        Write-Status "Stopping demo server..." "INFO"
        Stop-Job $serverJob -Force
        Remove-Job $serverJob -Force
    }
}
else {
    Write-Status "Demo failed to start" "ERROR"
}
