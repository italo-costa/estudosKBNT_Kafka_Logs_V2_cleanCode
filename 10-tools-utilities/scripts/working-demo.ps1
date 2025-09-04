# KBNT Simple Demo - Working Version
param([int]$Messages = 20)

function Write-Status {
    param([string]$Text, [string]$Type = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $color = "Cyan"
    if ($Type -eq "SUCCESS") { $color = "Green" }
    if ($Type -eq "ERROR") { $color = "Red" }
    Write-Host "[$time] [$Type] $Text" -ForegroundColor $color
}

Write-Status "=== KBNT SIMPLE DEMO TRAFFIC TEST ===" "INFO"
Write-Status "Testing with $Messages messages" "INFO"

$products = @(
    @{ Id = "DEMO-SMARTPHONE-001"; Price = 599.99 },
    @{ Id = "DEMO-TABLET-002"; Price = 399.99 },
    @{ Id = "DEMO-LAPTOP-003"; Price = 1299.99 }
)

$operations = @("INCREASE", "DECREASE", "SET")
$successCount = 0
$failCount = 0
$results = @()

for ($i = 1; $i -le $Messages; $i++) {
    $correlationId = "DEMO-$(Get-Date -UFormat %s)-$i"
    $product = $products | Get-Random
    $operation = $operations | Get-Random
    $quantity = Get-Random -Minimum 100 -Maximum 1000
    $processingTime = Get-Random -Minimum 50 -Maximum 200
    
    # Simulate processing
    Start-Sleep -Milliseconds 100
    
    $status = if ((Get-Random) % 10 -gt 0) { "SUCCESS" } else { "FAILED" }
    
    $result = @{
        CorrelationId = $correlationId
        ProductId = $product.Id
        Operation = $operation
        Quantity = $quantity
        Price = $product.Price
        ProcessingTime = $processingTime
        Status = $status
        Timestamp = (Get-Date)
    }
    
    $results += $result
    
    if ($status -eq "SUCCESS") {
        $successCount++
        Write-Status "Message $i processed: $correlationId - $($product.Id)" "SUCCESS"
    } else {
        $failCount++
        Write-Status "Message $i failed: $correlationId" "ERROR"
    }
    
    if ($i % 5 -eq 0) {
        Write-Status "Progress: $i/$Messages (Success: $successCount, Failed: $failCount)" "INFO"
    }
}

Write-Status "=== DEMO RESULTS ===" "SUCCESS"
Write-Status "Total Messages: $Messages" "INFO"
Write-Status "Successful: $successCount" "SUCCESS"
Write-Status "Failed: $failCount" "INFO"

if ($Messages -gt 0) {
    $successRate = [Math]::Round(($successCount * 100 / $Messages), 2)
    Write-Status "Success Rate: $successRate%" "SUCCESS"
}

if ($results.Count -gt 0) {
    $avgTime = ($results | Measure-Object -Property ProcessingTime -Average).Average
    Write-Status "Average Processing Time: $([Math]::Round($avgTime, 2)) ms" "INFO"
}

Write-Status "Sample Results:" "INFO"
$results | Select-Object -First 3 | ForEach-Object {
    Write-Status "  $($_.CorrelationId): $($_.ProductId) - $($_.Status)" "INFO"
}

Write-Status "Demo completed successfully!" "SUCCESS"
